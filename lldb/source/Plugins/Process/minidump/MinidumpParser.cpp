//===-- MinidumpParser.cpp ------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MinidumpParser.h"
#include "NtStructures.h"
#include "RegisterContextMinidump_x86_32.h"

#include "Plugins/Process/Utility/LinuxProcMaps.h"
#include "lldb/Utility/LLDBAssert.h"
#include "lldb/Utility/LLDBLog.h"
#include "lldb/Utility/Log.h"

// C includes
// C++ includes
#include <algorithm>
#include <map>
#include <optional>
#include <utility>
#include <vector>

using namespace lldb_private;
using namespace minidump;

llvm::Expected<MinidumpParser>
MinidumpParser::Create(const lldb::DataBufferSP &data_sp) {
  auto ExpectedFile = llvm::object::MinidumpFile::create(
      llvm::MemoryBufferRef(toStringRef(data_sp->GetData()), "minidump"));
  if (!ExpectedFile)
    return ExpectedFile.takeError();

  return MinidumpParser(data_sp, std::move(*ExpectedFile));
}

MinidumpParser::MinidumpParser(lldb::DataBufferSP data_sp,
                               std::unique_ptr<llvm::object::MinidumpFile> file)
    : m_data_sp(std::move(data_sp)), m_file(std::move(file)) {}

llvm::ArrayRef<uint8_t> MinidumpParser::GetData() {
  return llvm::ArrayRef<uint8_t>(m_data_sp->GetBytes(),
                                 m_data_sp->GetByteSize());
}

llvm::ArrayRef<uint8_t> MinidumpParser::GetStream(StreamType stream_type) {
  return m_file->getRawStream(stream_type).value_or(llvm::ArrayRef<uint8_t>());
}

std::optional<llvm::ArrayRef<uint8_t>>
MinidumpParser::GetRawStream(StreamType stream_type) {
  return m_file->getRawStream(stream_type);
}

UUID MinidumpParser::GetModuleUUID(const minidump::Module *module) {
  auto cv_record =
      GetData().slice(module->CvRecord.RVA, module->CvRecord.DataSize);

  // Read the CV record signature
  const llvm::support::ulittle32_t *signature = nullptr;
  Status error = consumeObject(cv_record, signature);
  if (error.Fail())
    return UUID();

  const CvSignature cv_signature =
      static_cast<CvSignature>(static_cast<uint32_t>(*signature));

  if (cv_signature == CvSignature::Pdb70) {
    const UUID::CvRecordPdb70 *pdb70_uuid = nullptr;
    Status error = consumeObject(cv_record, pdb70_uuid);
    if (error.Fail())
      return UUID();
    if (GetArchitecture().GetTriple().isOSBinFormatELF()) {
      if (pdb70_uuid->Age != 0)
        return UUID(pdb70_uuid, sizeof(*pdb70_uuid));
      return UUID(&pdb70_uuid->Uuid, sizeof(pdb70_uuid->Uuid));
    }
    return UUID(*pdb70_uuid);
  } else if (cv_signature == CvSignature::ElfBuildId)
    return UUID(cv_record);

  return UUID();
}

llvm::ArrayRef<minidump::Thread> MinidumpParser::GetThreads() {
  auto ExpectedThreads = GetMinidumpFile().getThreadList();
  if (ExpectedThreads)
    return *ExpectedThreads;

  LLDB_LOG_ERROR(GetLog(LLDBLog::Thread), ExpectedThreads.takeError(),
                 "Failed to read thread list: {0}");
  return {};
}

llvm::ArrayRef<uint8_t>
MinidumpParser::GetThreadContext(const LocationDescriptor &location) {
  if (location.RVA + location.DataSize > GetData().size())
    return {};
  return GetData().slice(location.RVA, location.DataSize);
}

llvm::ArrayRef<uint8_t>
MinidumpParser::GetThreadContext(const minidump::Thread &td) {
  return GetThreadContext(td.Context);
}

llvm::ArrayRef<uint8_t>
MinidumpParser::GetThreadContextWow64(const minidump::Thread &td) {
  Log *log = GetLog(LLDBLog::Process);
  // On Windows, a 32-bit process can run on a 64-bit machine under WOW64. If
  // the minidump was captured with a 64-bit debugger, then the CONTEXT we just
  // grabbed from the mini_dump_thread is the one for the 64-bit "native"
  // process rather than the 32-bit "guest" process we care about.  In this
  // case, we can get the 32-bit CONTEXT from the TEB (Thread Environment
  // Block) of the 64-bit process.
  auto teb_mem_maybe = GetMemory(td.EnvironmentBlock, sizeof(TEB64));
  if (!teb_mem_maybe) {
    LLDB_LOG_ERROR(log, teb_mem_maybe.takeError(),
                   "Failed to read Thread Environment Block: {0}");
    return {};
  }

  auto teb_mem = *teb_mem_maybe;
  if (teb_mem.empty())
    return {};

  const TEB64 *wow64teb;
  Status error = consumeObject(teb_mem, wow64teb);
  if (error.Fail())
    return {};

  // Slot 1 of the thread-local storage in the 64-bit TEB points to a structure
  // that includes the 32-bit CONTEXT (after a ULONG). See:
  // https://msdn.microsoft.com/en-us/library/ms681670.aspx
  auto context_maybe =
      GetMemory(wow64teb->tls_slots[1] + 4, sizeof(MinidumpContext_x86_32));
  if (!context_maybe) {
    LLDB_LOG_ERROR(log, context_maybe.takeError(),
                   "Failed to read WOW Thread Context: {0}");
    return {};
  }

  auto context = *context_maybe;

  if (context.size() < sizeof(MinidumpContext_x86_32))
    return {};

  return context;
  // NOTE:  We don't currently use the TEB for anything else.  If we
  // need it in the future, the 32-bit TEB is located according to the address
  // stored in the first slot of the 64-bit TEB (wow64teb.Reserved1[0]).
}

ArchSpec MinidumpParser::GetArchitecture() {
  if (m_arch.IsValid())
    return m_arch;

  // Set the architecture in m_arch
  llvm::Expected<const SystemInfo &> system_info = m_file->getSystemInfo();

  if (!system_info) {
    LLDB_LOG_ERROR(GetLog(LLDBLog::Process), system_info.takeError(),
                   "Failed to read SystemInfo stream: {0}");
    return m_arch;
  }

  // TODO what to do about big endiand flavors of arm ?
  // TODO set the arm subarch stuff if the minidump has info about it

  llvm::Triple triple;
  triple.setVendor(llvm::Triple::VendorType::UnknownVendor);

  switch (system_info->ProcessorArch) {
  case ProcessorArchitecture::X86:
    triple.setArch(llvm::Triple::ArchType::x86);
    break;
  case ProcessorArchitecture::AMD64:
    triple.setArch(llvm::Triple::ArchType::x86_64);
    break;
  case ProcessorArchitecture::ARM:
    triple.setArch(llvm::Triple::ArchType::arm);
    break;
  case ProcessorArchitecture::ARM64:
  case ProcessorArchitecture::BP_ARM64:
    triple.setArch(llvm::Triple::ArchType::aarch64);
    break;
  default:
    triple.setArch(llvm::Triple::ArchType::UnknownArch);
    break;
  }

  // TODO add all of the OSes that Minidump/breakpad distinguishes?
  switch (system_info->PlatformId) {
  case OSPlatform::Win32S:
  case OSPlatform::Win32Windows:
  case OSPlatform::Win32NT:
  case OSPlatform::Win32CE:
    triple.setOS(llvm::Triple::OSType::Win32);
    triple.setVendor(llvm::Triple::VendorType::PC);
    break;
  case OSPlatform::Linux:
    triple.setOS(llvm::Triple::OSType::Linux);
    break;
  case OSPlatform::MacOSX:
    triple.setOS(llvm::Triple::OSType::MacOSX);
    triple.setVendor(llvm::Triple::Apple);
    break;
  case OSPlatform::IOS:
    triple.setOS(llvm::Triple::OSType::IOS);
    triple.setVendor(llvm::Triple::Apple);
    break;
  case OSPlatform::Android:
    triple.setOS(llvm::Triple::OSType::Linux);
    triple.setEnvironment(llvm::Triple::EnvironmentType::Android);
    break;
  default: {
    triple.setOS(llvm::Triple::OSType::UnknownOS);
    auto ExpectedCSD = m_file->getString(system_info->CSDVersionRVA);
    if (!ExpectedCSD) {
      LLDB_LOG_ERROR(GetLog(LLDBLog::Process), ExpectedCSD.takeError(),
                     "Failed to CSD Version string: {0}");
    } else {
      if (ExpectedCSD->find("Linux") != std::string::npos)
        triple.setOS(llvm::Triple::OSType::Linux);
    }
    break;
  }
  }
  m_arch.SetTriple(triple);
  return m_arch;
}

const MinidumpMiscInfo *MinidumpParser::GetMiscInfo() {
  llvm::ArrayRef<uint8_t> data = GetStream(StreamType::MiscInfo);

  if (data.size() == 0)
    return nullptr;

  return MinidumpMiscInfo::Parse(data);
}

std::optional<LinuxProcStatus> MinidumpParser::GetLinuxProcStatus() {
  llvm::ArrayRef<uint8_t> data = GetStream(StreamType::LinuxProcStatus);

  if (data.size() == 0)
    return std::nullopt;

  return LinuxProcStatus::Parse(data);
}

std::optional<lldb::pid_t> MinidumpParser::GetPid() {
  const MinidumpMiscInfo *misc_info = GetMiscInfo();
  if (misc_info != nullptr) {
    return misc_info->GetPid();
  }

  std::optional<LinuxProcStatus> proc_status = GetLinuxProcStatus();
  if (proc_status) {
    return proc_status->GetPid();
  }

  return std::nullopt;
}

llvm::ArrayRef<minidump::Module> MinidumpParser::GetModuleList() {
  auto ExpectedModules = GetMinidumpFile().getModuleList();
  if (ExpectedModules)
    return *ExpectedModules;

  LLDB_LOG_ERROR(GetLog(LLDBLog::Modules), ExpectedModules.takeError(),
                 "Failed to read module list: {0}");
  return {};
}

static bool
CreateRegionsCacheFromLinuxMaps(MinidumpParser &parser,
                                std::vector<MemoryRegionInfo> &regions) {
  auto data = parser.GetStream(StreamType::LinuxMaps);
  if (data.empty())
    return false;

  Log *log = GetLog(LLDBLog::Expressions);
  ParseLinuxMapRegions(
      llvm::toStringRef(data),
      [&regions, &log](llvm::Expected<MemoryRegionInfo> region) -> bool {
        if (region)
          regions.push_back(*region);
        else
          LLDB_LOG_ERROR(log, region.takeError(),
                         "Reading memory region from minidump failed: {0}");
        return true;
      });
  return !regions.empty();
}

/// Check for the memory regions starting at \a load_addr for a contiguous
/// section that has execute permissions that matches the module path.
///
/// When we load a breakpad generated minidump file, we might have the
/// /proc/<pid>/maps text for a process that details the memory map of the
/// process that the minidump is describing. This checks the sorted memory
/// regions for a section that has execute permissions. A sample maps files
/// might look like:
///
/// 00400000-00401000 r--p 00000000 fd:01 2838574           /tmp/a.out
/// 00401000-00402000 r-xp 00001000 fd:01 2838574           /tmp/a.out
/// 00402000-00403000 r--p 00002000 fd:01 2838574           /tmp/a.out
/// 00403000-00404000 r--p 00002000 fd:01 2838574           /tmp/a.out
/// 00404000-00405000 rw-p 00003000 fd:01 2838574           /tmp/a.out
/// ...
///
/// This function should return true when given 0x00400000 and "/tmp/a.out"
/// is passed in as the path since it has a consecutive memory region for
/// "/tmp/a.out" that has execute permissions at 0x00401000. This will help us
/// differentiate if a file has been memory mapped into a process for reading
/// and breakpad ends up saving a minidump file that has two module entries for
/// a given file: one that is read only for the entire file, and then one that
/// is the real executable that is loaded into memory for execution. For memory
/// mapped files they will typically show up and r--p permissions and a range
/// matcning the entire range of the file on disk:
///
/// 00800000-00805000 r--p 00000000 fd:01 2838574           /tmp/a.out
/// 00805000-00806000 r-xp 00001000 fd:01 1234567           /usr/lib/libc.so
///
/// This function should return false when asked about 0x00800000 with
/// "/tmp/a.out" as the path.
///
/// \param[in] path
///   The path to the module to check for in the memory regions. Only sequential
///   memory regions whose paths match this path will be considered when looking
///   for execute permissions.
///
/// \param[in] regions
///   A sorted list of memory regions obtained from a call to
///   CreateRegionsCacheFromLinuxMaps.
///
/// \param[in] base_of_image
///   The load address of this module from BaseOfImage in the modules list.
///
/// \return
///   True if a contiguous region of memory belonging to the module with a
///   matching path exists that has executable permissions. Returns false if
///   \a regions is empty or if there are no regions with execute permissions
///   that match \a path.

static bool CheckForLinuxExecutable(ConstString path,
                                    const MemoryRegionInfos &regions,
                                    lldb::addr_t base_of_image) {
  if (regions.empty())
    return false;
  lldb::addr_t addr = base_of_image;
  MemoryRegionInfo region = MinidumpParser::GetMemoryRegionInfo(regions, addr);
  while (region.GetName() == path) {
    if (region.GetExecutable() == MemoryRegionInfo::eYes)
      return true;
    addr += region.GetRange().GetByteSize();
    region = MinidumpParser::GetMemoryRegionInfo(regions, addr);
  }
  return false;
}

std::vector<const minidump::Module *> MinidumpParser::GetFilteredModuleList() {
  Log *log = GetLog(LLDBLog::Modules);
  auto ExpectedModules = GetMinidumpFile().getModuleList();
  if (!ExpectedModules) {
    LLDB_LOG_ERROR(log, ExpectedModules.takeError(),
                   "Failed to read module list: {0}");
    return {};
  }

  // Create memory regions from the linux maps only. We do this to avoid issues
  // with breakpad generated minidumps where if someone has mmap'ed a shared
  // library into memory to access its data in the object file, we can get a
  // minidump with two mappings for a binary: one whose base image points to a
  // memory region that is read + execute and one that is read only.
  MemoryRegionInfos linux_regions;
  if (CreateRegionsCacheFromLinuxMaps(*this, linux_regions))
    llvm::sort(linux_regions);

  // map module_name -> filtered_modules index
  typedef llvm::StringMap<size_t> MapType;
  MapType module_name_to_filtered_index;

  std::vector<const minidump::Module *> filtered_modules;

  for (const auto &module : *ExpectedModules) {
    auto ExpectedName = m_file->getString(module.ModuleNameRVA);
    if (!ExpectedName) {
      LLDB_LOG_ERROR(log, ExpectedName.takeError(),
                     "Failed to get module name: {0}");
      continue;
    }

    MapType::iterator iter;
    bool inserted;
    // See if we have inserted this module aready into filtered_modules. If we
    // haven't insert an entry into module_name_to_filtered_index with the
    // index where we will insert it if it isn't in the vector already.
    std::tie(iter, inserted) = module_name_to_filtered_index.try_emplace(
        *ExpectedName, filtered_modules.size());

    if (inserted) {
      // This module has not been seen yet, insert it into filtered_modules at
      // the index that was inserted into module_name_to_filtered_index using
      // "filtered_modules.size()" above.
      filtered_modules.push_back(&module);
    } else {
      // We have a duplicate module entry. Check the linux regions to see if
      // either module is not really a mapped executable. If one but not the
      // other is a real mapped executable, prefer the executable one. This
      // can happen when a process mmap's in the file for an executable in
      // order to read bytes from the executable file. A memory region mapping
      // will exist for the mmap'ed version and for the loaded executable, but
      // only one will have a consecutive region that is executable in the
      // memory regions.
      auto dup_module = filtered_modules[iter->second];
      ConstString name(*ExpectedName);
      bool is_executable =
          CheckForLinuxExecutable(name, linux_regions, module.BaseOfImage);
      bool dup_is_executable =
          CheckForLinuxExecutable(name, linux_regions, dup_module->BaseOfImage);

      if (is_executable != dup_is_executable) {
        if (is_executable)
          filtered_modules[iter->second] = &module;
        continue;
      }
      // This module has been seen. Modules are sometimes mentioned multiple
      // times when they are mapped discontiguously, so find the module with
      // the lowest "base_of_image" and use that as the filtered module.
      if (module.BaseOfImage < dup_module->BaseOfImage)
        filtered_modules[iter->second] = &module;
    }
  }
  return filtered_modules;
}

llvm::iterator_range<ExceptionStreamsIterator>
MinidumpParser::GetExceptionStreams() {
  return GetMinidumpFile().getExceptionStreams();
}

std::optional<minidump::Range>
MinidumpParser::FindMemoryRange(lldb::addr_t addr) {
  if (m_memory_ranges.IsEmpty())
    PopulateMemoryRanges();

  const MemoryRangeVector::Entry *entry =
      m_memory_ranges.FindEntryThatContains(addr);
  if (!entry)
    return std::nullopt;

  return entry->data;
}

void MinidumpParser::PopulateMemoryRanges() {
  Log *log = GetLog(LLDBLog::Modules);
  auto ExpectedMemory = GetMinidumpFile().getMemoryList();
  if (ExpectedMemory) {
    for (const auto &memory_desc : *ExpectedMemory) {
      const LocationDescriptor &loc_desc = memory_desc.Memory;
      const lldb::addr_t range_start = memory_desc.StartOfMemoryRange;
      const size_t range_size = loc_desc.DataSize;
      auto ExpectedSlice = GetMinidumpFile().getRawData(loc_desc);
      if (!ExpectedSlice) {
        LLDB_LOG_ERROR(log, ExpectedSlice.takeError(),
                       "Failed to get memory slice: {0}");
        continue;
      }
      m_memory_ranges.Append(MemoryRangeVector::Entry(
          range_start, range_size,
          minidump::Range(range_start, *ExpectedSlice)));
    }
  } else {
    LLDB_LOG_ERROR(log, ExpectedMemory.takeError(),
                   "Failed to read memory list: {0}");
  }

  if (!GetStream(StreamType::Memory64List).empty()) {
    llvm::Error err = llvm::Error::success();
    for (const auto &memory_desc : GetMinidumpFile().getMemory64List(err)) {
      m_memory_ranges.Append(MemoryRangeVector::Entry(
          memory_desc.first.StartOfMemoryRange, memory_desc.first.DataSize,
          minidump::Range(memory_desc.first.StartOfMemoryRange,
                          memory_desc.second)));
    }

    if (err)
      LLDB_LOG_ERROR(log, std::move(err), "Failed to read memory64 list: {0}");
  }

  m_memory_ranges.Sort();
}

llvm::Expected<llvm::ArrayRef<uint8_t>>
MinidumpParser::GetMemory(lldb::addr_t addr, size_t size) {
  std::optional<minidump::Range> range = FindMemoryRange(addr);
  if (!range)
    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "No memory range found for address (0x%" PRIx64 ")", addr);

  // There's at least some overlap between the beginning of the desired range
  // (addr) and the current range.  Figure out where the overlap begins and
  // how much overlap there is.

  const size_t offset = addr - range->start;

  if (addr < range->start || offset >= range->range_ref.size())
    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "Address (0x%" PRIx64 ") is not in range [0x%" PRIx64 " - 0x%" PRIx64
        ")",
        addr, range->start, range->start + range->range_ref.size());

  const size_t overlap = std::min(size, range->range_ref.size() - offset);
  return range->range_ref.slice(offset, overlap);
}

llvm::iterator_range<FallibleMemory64Iterator>
MinidumpParser::GetMemory64Iterator(llvm::Error &err) {
  llvm::ErrorAsOutParameter ErrAsOutParam(&err);
  return m_file->getMemory64List(err);
}

static bool
CreateRegionsCacheFromMemoryInfoList(MinidumpParser &parser,
                                     std::vector<MemoryRegionInfo> &regions) {
  Log *log = GetLog(LLDBLog::Modules);
  auto ExpectedInfo = parser.GetMinidumpFile().getMemoryInfoList();
  if (!ExpectedInfo) {
    LLDB_LOG_ERROR(log, ExpectedInfo.takeError(),
                   "Failed to read memory info list: {0}");
    return false;
  }
  constexpr auto yes = MemoryRegionInfo::eYes;
  constexpr auto no = MemoryRegionInfo::eNo;
  for (const MemoryInfo &entry : *ExpectedInfo) {
    MemoryRegionInfo region;
    region.GetRange().SetRangeBase(entry.BaseAddress);
    region.GetRange().SetByteSize(entry.RegionSize);

    MemoryProtection prot = entry.Protect;
    region.SetReadable(bool(prot & MemoryProtection::NoAccess) ? no : yes);
    region.SetWritable(
        bool(prot & (MemoryProtection::ReadWrite | MemoryProtection::WriteCopy |
                     MemoryProtection::ExecuteReadWrite |
                     MemoryProtection::ExeciteWriteCopy))
            ? yes
            : no);
    region.SetExecutable(
        bool(prot & (MemoryProtection::Execute | MemoryProtection::ExecuteRead |
                     MemoryProtection::ExecuteReadWrite |
                     MemoryProtection::ExeciteWriteCopy))
            ? yes
            : no);
    region.SetMapped(entry.State != MemoryState::Free ? yes : no);
    regions.push_back(region);
  }
  return !regions.empty();
}

static bool
CreateRegionsCacheFromMemoryList(MinidumpParser &parser,
                                 std::vector<MemoryRegionInfo> &regions) {
  Log *log = GetLog(LLDBLog::Modules);
  // Cache the expected memory32 into an optional
  // because it is possible to just have a memory64 list
  auto ExpectedMemory = parser.GetMinidumpFile().getMemoryList();
  if (!ExpectedMemory) {
    LLDB_LOG_ERROR(log, ExpectedMemory.takeError(),
                   "Failed to read memory list: {0}");
  } else {
    for (const MemoryDescriptor &memory_desc : *ExpectedMemory) {
      if (memory_desc.Memory.DataSize == 0)
        continue;
      MemoryRegionInfo region;
      region.GetRange().SetRangeBase(memory_desc.StartOfMemoryRange);
      region.GetRange().SetByteSize(memory_desc.Memory.DataSize);
      region.SetReadable(MemoryRegionInfo::eYes);
      region.SetMapped(MemoryRegionInfo::eYes);
      regions.push_back(region);
    }
  }

  if (!parser.GetStream(StreamType::Memory64List).empty()) {
    llvm::Error err = llvm::Error::success();
    for (const auto &memory_desc : parser.GetMemory64Iterator(err)) {
      if (memory_desc.first.DataSize == 0)
        continue;
      MemoryRegionInfo region;
      region.GetRange().SetRangeBase(memory_desc.first.StartOfMemoryRange);
      region.GetRange().SetByteSize(memory_desc.first.DataSize);
      region.SetReadable(MemoryRegionInfo::eYes);
      region.SetMapped(MemoryRegionInfo::eYes);
      regions.push_back(region);
    }

    if (err) {
      LLDB_LOG_ERROR(log, std::move(err), "Failed to read memory64 list: {0}");
      return false;
    }
  }

  regions.shrink_to_fit();
  return !regions.empty();
}

std::pair<MemoryRegionInfos, bool> MinidumpParser::BuildMemoryRegions() {
  // We create the region cache using the best source. We start with
  // the linux maps since they are the most complete and have names for the
  // regions. Next we try the MemoryInfoList since it has
  // read/write/execute/map data, and then fall back to the MemoryList and
  // Memory64List to just get a list of the memory that is mapped in this
  // core file
  MemoryRegionInfos result;
  const auto &return_sorted = [&](bool is_complete) {
    llvm::sort(result);
    return std::make_pair(std::move(result), is_complete);
  };
  if (CreateRegionsCacheFromLinuxMaps(*this, result))
    return return_sorted(true);
  if (CreateRegionsCacheFromMemoryInfoList(*this, result))
    return return_sorted(true);
  CreateRegionsCacheFromMemoryList(*this, result);
  return return_sorted(false);
}

#define ENUM_TO_CSTR(ST)                                                       \
  case StreamType::ST:                                                         \
    return #ST

llvm::StringRef MinidumpParser::GetStreamTypeAsString(StreamType stream_type) {
  switch (stream_type) {
    ENUM_TO_CSTR(Unused);
    ENUM_TO_CSTR(ThreadList);
    ENUM_TO_CSTR(ModuleList);
    ENUM_TO_CSTR(MemoryList);
    ENUM_TO_CSTR(Exception);
    ENUM_TO_CSTR(SystemInfo);
    ENUM_TO_CSTR(ThreadExList);
    ENUM_TO_CSTR(Memory64List);
    ENUM_TO_CSTR(CommentA);
    ENUM_TO_CSTR(CommentW);
    ENUM_TO_CSTR(HandleData);
    ENUM_TO_CSTR(FunctionTable);
    ENUM_TO_CSTR(UnloadedModuleList);
    ENUM_TO_CSTR(MiscInfo);
    ENUM_TO_CSTR(MemoryInfoList);
    ENUM_TO_CSTR(ThreadInfoList);
    ENUM_TO_CSTR(HandleOperationList);
    ENUM_TO_CSTR(Token);
    ENUM_TO_CSTR(JavascriptData);
    ENUM_TO_CSTR(SystemMemoryInfo);
    ENUM_TO_CSTR(ProcessVMCounters);
    ENUM_TO_CSTR(LastReserved);
    ENUM_TO_CSTR(BreakpadInfo);
    ENUM_TO_CSTR(AssertionInfo);
    ENUM_TO_CSTR(LinuxCPUInfo);
    ENUM_TO_CSTR(LinuxProcStatus);
    ENUM_TO_CSTR(LinuxLSBRelease);
    ENUM_TO_CSTR(LinuxCMDLine);
    ENUM_TO_CSTR(LinuxEnviron);
    ENUM_TO_CSTR(LinuxAuxv);
    ENUM_TO_CSTR(LinuxMaps);
    ENUM_TO_CSTR(LinuxDSODebug);
    ENUM_TO_CSTR(LinuxProcStat);
    ENUM_TO_CSTR(LinuxProcUptime);
    ENUM_TO_CSTR(LinuxProcFD);
    ENUM_TO_CSTR(FacebookAppCustomData);
    ENUM_TO_CSTR(FacebookBuildID);
    ENUM_TO_CSTR(FacebookAppVersionName);
    ENUM_TO_CSTR(FacebookJavaStack);
    ENUM_TO_CSTR(FacebookDalvikInfo);
    ENUM_TO_CSTR(FacebookUnwindSymbols);
    ENUM_TO_CSTR(FacebookDumpErrorLog);
    ENUM_TO_CSTR(FacebookAppStateLog);
    ENUM_TO_CSTR(FacebookAbortReason);
    ENUM_TO_CSTR(FacebookThreadName);
    ENUM_TO_CSTR(FacebookLogcat);
    ENUM_TO_CSTR(LLDBGenerated);
  }
  return "unknown stream type";
}

MemoryRegionInfo
MinidumpParser::GetMemoryRegionInfo(const MemoryRegionInfos &regions,
                                    lldb::addr_t load_addr) {
  MemoryRegionInfo region;
  auto pos = llvm::upper_bound(regions, load_addr);
  if (pos != regions.begin() &&
      std::prev(pos)->GetRange().Contains(load_addr)) {
    return *std::prev(pos);
  }

  if (pos == regions.begin())
    region.GetRange().SetRangeBase(0);
  else
    region.GetRange().SetRangeBase(std::prev(pos)->GetRange().GetRangeEnd());

  if (pos == regions.end())
    region.GetRange().SetRangeEnd(UINT64_MAX);
  else
    region.GetRange().SetRangeEnd(pos->GetRange().GetRangeBase());

  region.SetReadable(MemoryRegionInfo::eNo);
  region.SetWritable(MemoryRegionInfo::eNo);
  region.SetExecutable(MemoryRegionInfo::eNo);
  region.SetMapped(MemoryRegionInfo::eNo);
  return region;
}
