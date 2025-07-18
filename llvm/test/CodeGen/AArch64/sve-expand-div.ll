; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=aarch64-linux-gnu < %s | FileCheck %s
; RUN: llc -mtriple=aarch64-linux-gnu -use-constant-int-for-scalable-splat < %s | FileCheck %s

; Check that expensive divides are expanded into a more performant sequence

;
; SDIV
;

define <vscale x 16 x i8> @sdiv_i8(<vscale x 16 x i8> %a) #0 {
; CHECK-LABEL: sdiv_i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov z1.b, #86 // =0x56
; CHECK-NEXT:    ptrue p0.b
; CHECK-NEXT:    smulh z0.b, p0/m, z0.b, z1.b
; CHECK-NEXT:    lsr z1.b, z0.b, #7
; CHECK-NEXT:    add z0.b, z0.b, z1.b
; CHECK-NEXT:    ret
  %div = sdiv <vscale x 16 x i8> %a, splat (i8 3)
  ret <vscale x 16 x i8> %div
}

define <vscale x 8 x i16> @sdiv_i16(<vscale x 8 x i16> %a) #0 {
; CHECK-LABEL: sdiv_i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov w8, #21846 // =0x5556
; CHECK-NEXT:    ptrue p0.h
; CHECK-NEXT:    mov z1.h, w8
; CHECK-NEXT:    smulh z0.h, p0/m, z0.h, z1.h
; CHECK-NEXT:    lsr z1.h, z0.h, #15
; CHECK-NEXT:    add z0.h, z0.h, z1.h
; CHECK-NEXT:    ret
  %div = sdiv <vscale x 8 x i16> %a, splat (i16 3)
  ret <vscale x 8 x i16> %div
}

define <vscale x 4 x i32> @sdiv_i32(<vscale x 4 x i32> %a) #0 {
; CHECK-LABEL: sdiv_i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov w8, #21846 // =0x5556
; CHECK-NEXT:    ptrue p0.s
; CHECK-NEXT:    movk w8, #21845, lsl #16
; CHECK-NEXT:    mov z1.s, w8
; CHECK-NEXT:    smulh z0.s, p0/m, z0.s, z1.s
; CHECK-NEXT:    lsr z1.s, z0.s, #31
; CHECK-NEXT:    add z0.s, z0.s, z1.s
; CHECK-NEXT:    ret
  %div = sdiv <vscale x 4 x i32> %a, splat (i32 3)
  ret <vscale x 4 x i32> %div
}

define <vscale x 2 x i64> @sdiv_i64(<vscale x 2 x i64> %a) #0 {
; CHECK-LABEL: sdiv_i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov x8, #6148914691236517205 // =0x5555555555555555
; CHECK-NEXT:    ptrue p0.d
; CHECK-NEXT:    movk x8, #21846
; CHECK-NEXT:    mov z1.d, x8
; CHECK-NEXT:    smulh z0.d, p0/m, z0.d, z1.d
; CHECK-NEXT:    lsr z1.d, z0.d, #63
; CHECK-NEXT:    add z0.d, z0.d, z1.d
; CHECK-NEXT:    ret
  %div = sdiv <vscale x 2 x i64> %a, splat (i64 3)
  ret <vscale x 2 x i64> %div
}

;
; UDIV
;

define <vscale x 16 x i8> @udiv_i8(<vscale x 16 x i8> %a) #0 {
; CHECK-LABEL: udiv_i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov z1.b, #-85 // =0xffffffffffffffab
; CHECK-NEXT:    ptrue p0.b
; CHECK-NEXT:    umulh z0.b, p0/m, z0.b, z1.b
; CHECK-NEXT:    lsr z0.b, z0.b, #1
; CHECK-NEXT:    ret
  %div = udiv <vscale x 16 x i8> %a, splat (i8 3)
  ret <vscale x 16 x i8> %div
}

define <vscale x 8 x i16> @udiv_i16(<vscale x 8 x i16> %a) #0 {
; CHECK-LABEL: udiv_i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov w8, #-21845 // =0xffffaaab
; CHECK-NEXT:    ptrue p0.h
; CHECK-NEXT:    mov z1.h, w8
; CHECK-NEXT:    umulh z0.h, p0/m, z0.h, z1.h
; CHECK-NEXT:    lsr z0.h, z0.h, #1
; CHECK-NEXT:    ret
  %div = udiv <vscale x 8 x i16> %a, splat (i16 3)
  ret <vscale x 8 x i16> %div
}

define <vscale x 4 x i32> @udiv_i32(<vscale x 4 x i32> %a) #0 {
; CHECK-LABEL: udiv_i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov w8, #43691 // =0xaaab
; CHECK-NEXT:    ptrue p0.s
; CHECK-NEXT:    movk w8, #43690, lsl #16
; CHECK-NEXT:    mov z1.s, w8
; CHECK-NEXT:    umulh z0.s, p0/m, z0.s, z1.s
; CHECK-NEXT:    lsr z0.s, z0.s, #1
; CHECK-NEXT:    ret
  %div = udiv <vscale x 4 x i32> %a, splat (i32 3)
  ret <vscale x 4 x i32> %div
}

define <vscale x 2 x i64> @udiv_i64(<vscale x 2 x i64> %a) #0 {
; CHECK-LABEL: udiv_i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov x8, #-6148914691236517206 // =0xaaaaaaaaaaaaaaaa
; CHECK-NEXT:    ptrue p0.d
; CHECK-NEXT:    movk x8, #43691
; CHECK-NEXT:    mov z1.d, x8
; CHECK-NEXT:    umulh z0.d, p0/m, z0.d, z1.d
; CHECK-NEXT:    lsr z0.d, z0.d, #1
; CHECK-NEXT:    ret
  %div = udiv <vscale x 2 x i64> %a, splat (i64 3)
  ret <vscale x 2 x i64> %div
}

attributes #0 = { "target-features"="+sve" }
