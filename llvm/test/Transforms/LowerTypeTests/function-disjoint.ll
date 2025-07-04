; RUN: opt -S -passes=lowertypetests -mtriple=x86_64-unknown-linux-gnu %s | FileCheck --check-prefix=X64 %s
; RUN: opt -S -passes=lowertypetests -mtriple=wasm32-unknown-unknown %s | FileCheck --check-prefix=WASM32 %s

; Tests that we correctly handle bitsets with disjoint call target sets.

target datalayout = "e-p:64:64"

; X64: @g = alias [8 x i8], ptr @[[JT1:.*]]
; X64: @f = alias [8 x i8], ptr @[[JT0:.*]]

; WASM32: private constant [0 x i8] zeroinitializer
@0 = private unnamed_addr constant [2 x ptr] [ptr @f, ptr @g], align 16

; X64: define hidden void @f.cfi()
; WASM32: define void @f() !type !{{[0-9]+}} !wasm.index ![[I1:[0-9]+]]
define void @f() !type !0 {
  ret void
}

; X64: define hidden void @g.cfi()
; WASM32: define void @g() !type !{{[0-9]+}} !wasm.index ![[I0:[0-9]+]]
define void @g() !type !1 {
  ret void
}

!0 = !{i32 0, !"typeid1"}
!1 = !{i32 0, !"typeid2"}

declare i1 @llvm.type.test(ptr %ptr, metadata %bitset) nounwind readnone

define i1 @foo(ptr %p) {
  ; X64: icmp eq i64 {{.*}}, ptrtoint (ptr @[[JT0]] to i64)
  ; WASM32: icmp eq i64 {{.*}}, ptrtoint (ptr getelementptr (i8, ptr null, i64 2) to i64)
  %x = call i1 @llvm.type.test(ptr %p, metadata !"typeid1")
  ; X64: icmp eq i64 {{.*}}, ptrtoint (ptr @[[JT1]] to i64)
  ; WASM32: icmp eq i64 {{.*}}, ptrtoint (ptr getelementptr (i8, ptr null, i64 1) to i64)
  %y = call i1 @llvm.type.test(ptr %p, metadata !"typeid2")
  %z = add i1 %x, %y
  ret i1 %z
}

; X64: define private void @[[JT1]]() #{{.*}} align 8 {
; X64:   call void asm sideeffect "jmp ${0:c}@plt\0Aint3\0Aint3\0Aint3\0A", "s"(ptr @g.cfi)

; X64: define private void @[[JT0]]() #{{.*}} align 8 {
; X64:   call void asm sideeffect "jmp ${0:c}@plt\0Aint3\0Aint3\0Aint3\0A", "s"(ptr @f.cfi)

; WASM32: ![[I1]] = !{i64 2}
; WASM32: ![[I0]] = !{i64 1}
