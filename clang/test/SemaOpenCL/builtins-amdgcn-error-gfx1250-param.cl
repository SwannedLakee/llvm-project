// REQUIRES: amdgpu-registered-target
// RUN: %clang_cc1 -cl-std=CL2.0 -triple amdgcn-- -target-cpu gfx1250 -verify -S -o - %s

typedef int    v2i   __attribute__((ext_vector_type(2)));
typedef int    v4i   __attribute__((ext_vector_type(4)));
typedef int    v8i   __attribute__((ext_vector_type(8)));

void test_setprio_inc_wg(short a) {
  __builtin_amdgcn_s_setprio_inc_wg(a); // expected-error {{'__builtin_amdgcn_s_setprio_inc_wg' must be a constant integer}}
}

void test_s_monitor_sleep(short a) {
  __builtin_amdgcn_s_monitor_sleep(a); // expected-error {{'__builtin_amdgcn_s_monitor_sleep' must be a constant integer}}
}

void test_s_wait_asynccnt(short a) {
  __builtin_amdgcn_s_wait_asynccnt(a); // expected-error {{'__builtin_amdgcn_s_wait_asynccnt' must be a constant integer}}
}

void test_s_wait_tensorcnt(short a) {
  __builtin_amdgcn_s_wait_tensorcnt(a); // expected-error {{'__builtin_amdgcn_s_wait_tensorcnt' must be a constant integer}}
}

void test__builtin_amdgcn_cvt_f16_fp8(int a, int b) {
  __builtin_amdgcn_cvt_f16_fp8(a, b); // expected-error {{'__builtin_amdgcn_cvt_f16_fp8' must be a constant integer}}
}

void test__builtin_amdgcn_cvt_f16_bf8(int a, int b) {
  __builtin_amdgcn_cvt_f16_bf8(a, b); // expected-error {{'__builtin_amdgcn_cvt_f16_bf8' must be a constant integer}}
}

void test_amdgcn_load_monitor(global int* b32gaddr, global v2i* b64gaddr, global v4i* b128gaddr, int *b32faddr, v2i* b64faddr, v4i *b128faddr,
                              global int* b32out, global v2i* b64out, global v4i* b128out, int cpol)
{
  *b32out  = __builtin_amdgcn_global_load_monitor_b32(b32gaddr, cpol); // expected-error {{'__builtin_amdgcn_global_load_monitor_b32' must be a constant integer}}
  *b64out  = __builtin_amdgcn_global_load_monitor_b64(b64gaddr, cpol); // expected-error {{'__builtin_amdgcn_global_load_monitor_b64' must be a constant integer}}
  *b128out = __builtin_amdgcn_global_load_monitor_b128(b128gaddr, cpol); // expected-error {{'__builtin_amdgcn_global_load_monitor_b128' must be a constant integer}}
  *b32out  = __builtin_amdgcn_flat_load_monitor_b32(b32faddr, cpol); // expected-error {{'__builtin_amdgcn_flat_load_monitor_b32' must be a constant integer}}
  *b64out  = __builtin_amdgcn_flat_load_monitor_b64(b64faddr, cpol); // expected-error {{'__builtin_amdgcn_flat_load_monitor_b64' must be a constant integer}}
  *b128out = __builtin_amdgcn_flat_load_monitor_b128(b128faddr, cpol); // expected-error {{'__builtin_amdgcn_flat_load_monitor_b128' must be a constant integer}}
}

void test_amdgcn_tensor_load_store(v4i sg0, v8i sg1, v4i sg2, v4i sg3, int cpol)
{
  __builtin_amdgcn_tensor_load_to_lds(sg0, sg1, sg2, sg3, cpol); // expected-error {{'__builtin_amdgcn_tensor_load_to_lds' must be a constant integer}}
  __builtin_amdgcn_tensor_load_to_lds_d2(sg0, sg1, cpol); // expected-error {{'__builtin_amdgcn_tensor_load_to_lds_d2' must be a constant integer}}
  __builtin_amdgcn_tensor_store_from_lds(sg0, sg1, sg2, sg3, cpol); // expected-error {{'__builtin_amdgcn_tensor_store_from_lds' must be a constant integer}}
  __builtin_amdgcn_tensor_store_from_lds_d2(sg0, sg1, cpol); // expected-error {{'__builtin_amdgcn_tensor_store_from_lds_d2' must be a constant integer}}
}

void test_prefetch(generic void *fptr, global void *gptr, int cpol) {
  __builtin_amdgcn_flat_prefetch(fptr, cpol); // expected-error {{'__builtin_amdgcn_flat_prefetch' must be a constant integer}}
  __builtin_amdgcn_global_prefetch(gptr, cpol); // expected-error {{'__builtin_amdgcn_global_prefetch' must be a constant integer}}
}

void test_cvt_f32_fp8_e5m3(global int* out, int a)
{
  *out = __builtin_amdgcn_cvt_f32_fp8_e5m3(a, a); // expected-error {{'__builtin_amdgcn_cvt_f32_fp8_e5m3' must be a constant integer}}
}
