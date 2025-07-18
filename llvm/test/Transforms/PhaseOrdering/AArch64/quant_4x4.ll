; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 2
; RUN: opt -S -O3 < %s | FileCheck %s

target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64"

; Check that the function gets vectorized.

define i32 @quant_4x4(ptr noundef %dct, ptr noundef %mf, ptr noundef %bias) {
; CHECK-LABEL: define range(i32 0, 2) i32 @quant_4x4
; CHECK-SAME: (ptr noundef captures(none) [[DCT:%.*]], ptr noundef readonly captures(none) [[MF:%.*]], ptr noundef readonly captures(none) [[BIAS:%.*]]) local_unnamed_addr #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[DCT]], i64 32
; CHECK-NEXT:    [[SCEVGEP23:%.*]] = getelementptr i8, ptr [[BIAS]], i64 32
; CHECK-NEXT:    [[SCEVGEP24:%.*]] = getelementptr i8, ptr [[MF]], i64 32
; CHECK-NEXT:    [[BOUND0:%.*]] = icmp ult ptr [[DCT]], [[SCEVGEP23]]
; CHECK-NEXT:    [[BOUND1:%.*]] = icmp ult ptr [[BIAS]], [[SCEVGEP]]
; CHECK-NEXT:    [[FOUND_CONFLICT:%.*]] = and i1 [[BOUND0]], [[BOUND1]]
; CHECK-NEXT:    [[BOUND025:%.*]] = icmp ult ptr [[DCT]], [[SCEVGEP24]]
; CHECK-NEXT:    [[BOUND126:%.*]] = icmp ult ptr [[MF]], [[SCEVGEP]]
; CHECK-NEXT:    [[FOUND_CONFLICT27:%.*]] = and i1 [[BOUND025]], [[BOUND126]]
; CHECK-NEXT:    [[CONFLICT_RDX:%.*]] = or i1 [[FOUND_CONFLICT]], [[FOUND_CONFLICT27]]
; CHECK-NEXT:    br i1 [[CONFLICT_RDX]], label [[FOR_BODY:%.*]], label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[TMP0:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 16
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <8 x i16>, ptr [[DCT]], align 2, !alias.scope [[META0:![0-9]+]], !noalias [[META3:![0-9]+]]
; CHECK-NEXT:    [[WIDE_LOAD29:%.*]] = load <8 x i16>, ptr [[TMP0]], align 2, !alias.scope [[META0]], !noalias [[META3]]
; CHECK-NEXT:    [[TMP1:%.*]] = sext <8 x i16> [[WIDE_LOAD]] to <8 x i32>
; CHECK-NEXT:    [[TMP2:%.*]] = sext <8 x i16> [[WIDE_LOAD29]] to <8 x i32>
; CHECK-NEXT:    [[TMP3:%.*]] = icmp sgt <8 x i16> [[WIDE_LOAD]], zeroinitializer
; CHECK-NEXT:    [[TMP4:%.*]] = icmp sgt <8 x i16> [[WIDE_LOAD29]], zeroinitializer
; CHECK-NEXT:    [[TMP5:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 16
; CHECK-NEXT:    [[WIDE_LOAD30:%.*]] = load <8 x i16>, ptr [[BIAS]], align 2, !alias.scope [[META6:![0-9]+]]
; CHECK-NEXT:    [[WIDE_LOAD31:%.*]] = load <8 x i16>, ptr [[TMP5]], align 2, !alias.scope [[META6]]
; CHECK-NEXT:    [[TMP6:%.*]] = zext <8 x i16> [[WIDE_LOAD30]] to <8 x i32>
; CHECK-NEXT:    [[TMP7:%.*]] = zext <8 x i16> [[WIDE_LOAD31]] to <8 x i32>
; CHECK-NEXT:    [[TMP8:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 16
; CHECK-NEXT:    [[WIDE_LOAD32:%.*]] = load <8 x i16>, ptr [[MF]], align 2, !alias.scope [[META7:![0-9]+]]
; CHECK-NEXT:    [[WIDE_LOAD33:%.*]] = load <8 x i16>, ptr [[TMP8]], align 2, !alias.scope [[META7]]
; CHECK-NEXT:    [[TMP9:%.*]] = zext <8 x i16> [[WIDE_LOAD32]] to <8 x i32>
; CHECK-NEXT:    [[TMP10:%.*]] = zext <8 x i16> [[WIDE_LOAD33]] to <8 x i32>
; CHECK-NEXT:    [[TMP11:%.*]] = sub nsw <8 x i32> [[TMP6]], [[TMP1]]
; CHECK-NEXT:    [[TMP12:%.*]] = sub nsw <8 x i32> [[TMP7]], [[TMP2]]
; CHECK-NEXT:    [[TMP13:%.*]] = mul <8 x i32> [[TMP11]], [[TMP9]]
; CHECK-NEXT:    [[TMP14:%.*]] = mul <8 x i32> [[TMP12]], [[TMP10]]
; CHECK-NEXT:    [[TMP15:%.*]] = lshr <8 x i32> [[TMP13]], splat (i32 16)
; CHECK-NEXT:    [[TMP16:%.*]] = lshr <8 x i32> [[TMP14]], splat (i32 16)
; CHECK-NEXT:    [[TMP17:%.*]] = trunc nuw <8 x i32> [[TMP15]] to <8 x i16>
; CHECK-NEXT:    [[TMP18:%.*]] = trunc nuw <8 x i32> [[TMP16]] to <8 x i16>
; CHECK-NEXT:    [[TMP19:%.*]] = sub <8 x i16> zeroinitializer, [[TMP17]]
; CHECK-NEXT:    [[TMP20:%.*]] = sub <8 x i16> zeroinitializer, [[TMP18]]
; CHECK-NEXT:    [[TMP21:%.*]] = add nuw nsw <8 x i32> [[TMP6]], [[TMP1]]
; CHECK-NEXT:    [[TMP22:%.*]] = add nuw nsw <8 x i32> [[TMP7]], [[TMP2]]
; CHECK-NEXT:    [[TMP23:%.*]] = mul <8 x i32> [[TMP21]], [[TMP9]]
; CHECK-NEXT:    [[TMP24:%.*]] = mul <8 x i32> [[TMP22]], [[TMP10]]
; CHECK-NEXT:    [[TMP25:%.*]] = lshr <8 x i32> [[TMP23]], splat (i32 16)
; CHECK-NEXT:    [[TMP26:%.*]] = lshr <8 x i32> [[TMP24]], splat (i32 16)
; CHECK-NEXT:    [[TMP27:%.*]] = trunc nuw <8 x i32> [[TMP25]] to <8 x i16>
; CHECK-NEXT:    [[TMP28:%.*]] = trunc nuw <8 x i32> [[TMP26]] to <8 x i16>
; CHECK-NEXT:    [[PREDPHI:%.*]] = select <8 x i1> [[TMP3]], <8 x i16> [[TMP27]], <8 x i16> [[TMP19]]
; CHECK-NEXT:    [[PREDPHI34:%.*]] = select <8 x i1> [[TMP4]], <8 x i16> [[TMP28]], <8 x i16> [[TMP20]]
; CHECK-NEXT:    store <8 x i16> [[PREDPHI]], ptr [[DCT]], align 2, !alias.scope [[META0]], !noalias [[META3]]
; CHECK-NEXT:    store <8 x i16> [[PREDPHI34]], ptr [[TMP0]], align 2, !alias.scope [[META0]], !noalias [[META3]]
; CHECK-NEXT:    [[BIN_RDX35:%.*]] = or <8 x i16> [[PREDPHI34]], [[PREDPHI]]
; CHECK-NEXT:    [[TMP29:%.*]] = tail call i16 @llvm.vector.reduce.or.v8i16(<8 x i16> [[BIN_RDX35]])
; CHECK-NEXT:    br label [[FOR_COND_CLEANUP:%.*]]
; CHECK:       for.cond.cleanup:
; CHECK-NEXT:    [[OR_LCSSA_IN:%.*]] = phi i16 [ [[TMP29]], [[VECTOR_BODY]] ], [ [[OR_1551:%.*]], [[IF_END_15:%.*]] ]
; CHECK-NEXT:    [[TOBOOL:%.*]] = icmp ne i16 [[OR_LCSSA_IN]], 0
; CHECK-NEXT:    [[LNOT_EXT:%.*]] = zext i1 [[TOBOOL]] to i32
; CHECK-NEXT:    ret i32 [[LNOT_EXT]]
; CHECK:       for.body:
; CHECK-NEXT:    [[TMP30:%.*]] = load i16, ptr [[DCT]], align 2
; CHECK-NEXT:    [[CONV:%.*]] = sext i16 [[TMP30]] to i32
; CHECK-NEXT:    [[CMP1:%.*]] = icmp sgt i16 [[TMP30]], 0
; CHECK-NEXT:    [[TMP31:%.*]] = load i16, ptr [[BIAS]], align 2
; CHECK-NEXT:    [[CONV5:%.*]] = zext i16 [[TMP31]] to i32
; CHECK-NEXT:    [[TMP32:%.*]] = load i16, ptr [[MF]], align 2
; CHECK-NEXT:    [[CONV11:%.*]] = zext i16 [[TMP32]] to i32
; CHECK-NEXT:    br i1 [[CMP1]], label [[IF_THEN:%.*]], label [[IF_ELSE:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[ADD:%.*]] = add nuw nsw i32 [[CONV5]], [[CONV]]
; CHECK-NEXT:    [[MUL:%.*]] = mul i32 [[ADD]], [[CONV11]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i32 [[MUL]], 16
; CHECK-NEXT:    [[CONV12:%.*]] = trunc nuw i32 [[SHR]] to i16
; CHECK-NEXT:    br label [[IF_END:%.*]]
; CHECK:       if.else:
; CHECK-NEXT:    [[ADD21:%.*]] = sub nsw i32 [[CONV5]], [[CONV]]
; CHECK-NEXT:    [[MUL25:%.*]] = mul i32 [[ADD21]], [[CONV11]]
; CHECK-NEXT:    [[SHR26:%.*]] = lshr i32 [[MUL25]], 16
; CHECK-NEXT:    [[TMP33:%.*]] = trunc nuw i32 [[SHR26]] to i16
; CHECK-NEXT:    [[CONV28:%.*]] = sub i16 0, [[TMP33]]
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    [[STOREMERGE:%.*]] = phi i16 [ [[CONV28]], [[IF_ELSE]] ], [ [[CONV12]], [[IF_THEN]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE]], ptr [[DCT]], align 2
; CHECK-NEXT:    [[ARRAYIDX_1:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 2
; CHECK-NEXT:    [[TMP34:%.*]] = load i16, ptr [[ARRAYIDX_1]], align 2
; CHECK-NEXT:    [[CONV_1:%.*]] = sext i16 [[TMP34]] to i32
; CHECK-NEXT:    [[CMP1_1:%.*]] = icmp sgt i16 [[TMP34]], 0
; CHECK-NEXT:    [[ARRAYIDX4_1:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 2
; CHECK-NEXT:    [[TMP35:%.*]] = load i16, ptr [[ARRAYIDX4_1]], align 2
; CHECK-NEXT:    [[CONV5_1:%.*]] = zext i16 [[TMP35]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_1:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 2
; CHECK-NEXT:    [[TMP36:%.*]] = load i16, ptr [[ARRAYIDX10_1]], align 2
; CHECK-NEXT:    [[CONV11_1:%.*]] = zext i16 [[TMP36]] to i32
; CHECK-NEXT:    br i1 [[CMP1_1]], label [[IF_THEN_1:%.*]], label [[IF_ELSE_1:%.*]]
; CHECK:       if.else.1:
; CHECK-NEXT:    [[ADD21_1:%.*]] = sub nsw i32 [[CONV5_1]], [[CONV_1]]
; CHECK-NEXT:    [[MUL25_1:%.*]] = mul i32 [[ADD21_1]], [[CONV11_1]]
; CHECK-NEXT:    [[SHR26_1:%.*]] = lshr i32 [[MUL25_1]], 16
; CHECK-NEXT:    [[TMP37:%.*]] = trunc nuw i32 [[SHR26_1]] to i16
; CHECK-NEXT:    [[CONV28_1:%.*]] = sub i16 0, [[TMP37]]
; CHECK-NEXT:    br label [[IF_END_1:%.*]]
; CHECK:       if.then.1:
; CHECK-NEXT:    [[ADD_1:%.*]] = add nuw nsw i32 [[CONV5_1]], [[CONV_1]]
; CHECK-NEXT:    [[MUL_1:%.*]] = mul i32 [[ADD_1]], [[CONV11_1]]
; CHECK-NEXT:    [[SHR_1:%.*]] = lshr i32 [[MUL_1]], 16
; CHECK-NEXT:    [[CONV12_1:%.*]] = trunc nuw i32 [[SHR_1]] to i16
; CHECK-NEXT:    br label [[IF_END_1]]
; CHECK:       if.end.1:
; CHECK-NEXT:    [[STOREMERGE_1:%.*]] = phi i16 [ [[CONV28_1]], [[IF_ELSE_1]] ], [ [[CONV12_1]], [[IF_THEN_1]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_1]], ptr [[ARRAYIDX_1]], align 2
; CHECK-NEXT:    [[OR_137:%.*]] = or i16 [[STOREMERGE]], [[STOREMERGE_1]]
; CHECK-NEXT:    [[ARRAYIDX_2:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 4
; CHECK-NEXT:    [[TMP38:%.*]] = load i16, ptr [[ARRAYIDX_2]], align 2
; CHECK-NEXT:    [[CONV_2:%.*]] = sext i16 [[TMP38]] to i32
; CHECK-NEXT:    [[CMP1_2:%.*]] = icmp sgt i16 [[TMP38]], 0
; CHECK-NEXT:    [[ARRAYIDX4_2:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 4
; CHECK-NEXT:    [[TMP39:%.*]] = load i16, ptr [[ARRAYIDX4_2]], align 2
; CHECK-NEXT:    [[CONV5_2:%.*]] = zext i16 [[TMP39]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_2:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 4
; CHECK-NEXT:    [[TMP40:%.*]] = load i16, ptr [[ARRAYIDX10_2]], align 2
; CHECK-NEXT:    [[CONV11_2:%.*]] = zext i16 [[TMP40]] to i32
; CHECK-NEXT:    br i1 [[CMP1_2]], label [[IF_THEN_2:%.*]], label [[IF_ELSE_2:%.*]]
; CHECK:       if.else.2:
; CHECK-NEXT:    [[ADD21_2:%.*]] = sub nsw i32 [[CONV5_2]], [[CONV_2]]
; CHECK-NEXT:    [[MUL25_2:%.*]] = mul i32 [[ADD21_2]], [[CONV11_2]]
; CHECK-NEXT:    [[SHR26_2:%.*]] = lshr i32 [[MUL25_2]], 16
; CHECK-NEXT:    [[TMP41:%.*]] = trunc nuw i32 [[SHR26_2]] to i16
; CHECK-NEXT:    [[CONV28_2:%.*]] = sub i16 0, [[TMP41]]
; CHECK-NEXT:    br label [[IF_END_2:%.*]]
; CHECK:       if.then.2:
; CHECK-NEXT:    [[ADD_2:%.*]] = add nuw nsw i32 [[CONV5_2]], [[CONV_2]]
; CHECK-NEXT:    [[MUL_2:%.*]] = mul i32 [[ADD_2]], [[CONV11_2]]
; CHECK-NEXT:    [[SHR_2:%.*]] = lshr i32 [[MUL_2]], 16
; CHECK-NEXT:    [[CONV12_2:%.*]] = trunc nuw i32 [[SHR_2]] to i16
; CHECK-NEXT:    br label [[IF_END_2]]
; CHECK:       if.end.2:
; CHECK-NEXT:    [[STOREMERGE_2:%.*]] = phi i16 [ [[CONV28_2]], [[IF_ELSE_2]] ], [ [[CONV12_2]], [[IF_THEN_2]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_2]], ptr [[ARRAYIDX_2]], align 2
; CHECK-NEXT:    [[OR_238:%.*]] = or i16 [[OR_137]], [[STOREMERGE_2]]
; CHECK-NEXT:    [[ARRAYIDX_3:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 6
; CHECK-NEXT:    [[TMP42:%.*]] = load i16, ptr [[ARRAYIDX_3]], align 2
; CHECK-NEXT:    [[CONV_3:%.*]] = sext i16 [[TMP42]] to i32
; CHECK-NEXT:    [[CMP1_3:%.*]] = icmp sgt i16 [[TMP42]], 0
; CHECK-NEXT:    [[ARRAYIDX4_3:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 6
; CHECK-NEXT:    [[TMP43:%.*]] = load i16, ptr [[ARRAYIDX4_3]], align 2
; CHECK-NEXT:    [[CONV5_3:%.*]] = zext i16 [[TMP43]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_3:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 6
; CHECK-NEXT:    [[TMP44:%.*]] = load i16, ptr [[ARRAYIDX10_3]], align 2
; CHECK-NEXT:    [[CONV11_3:%.*]] = zext i16 [[TMP44]] to i32
; CHECK-NEXT:    br i1 [[CMP1_3]], label [[IF_THEN_3:%.*]], label [[IF_ELSE_3:%.*]]
; CHECK:       if.else.3:
; CHECK-NEXT:    [[ADD21_3:%.*]] = sub nsw i32 [[CONV5_3]], [[CONV_3]]
; CHECK-NEXT:    [[MUL25_3:%.*]] = mul i32 [[ADD21_3]], [[CONV11_3]]
; CHECK-NEXT:    [[SHR26_3:%.*]] = lshr i32 [[MUL25_3]], 16
; CHECK-NEXT:    [[TMP45:%.*]] = trunc nuw i32 [[SHR26_3]] to i16
; CHECK-NEXT:    [[CONV28_3:%.*]] = sub i16 0, [[TMP45]]
; CHECK-NEXT:    br label [[IF_END_3:%.*]]
; CHECK:       if.then.3:
; CHECK-NEXT:    [[ADD_3:%.*]] = add nuw nsw i32 [[CONV5_3]], [[CONV_3]]
; CHECK-NEXT:    [[MUL_3:%.*]] = mul i32 [[ADD_3]], [[CONV11_3]]
; CHECK-NEXT:    [[SHR_3:%.*]] = lshr i32 [[MUL_3]], 16
; CHECK-NEXT:    [[CONV12_3:%.*]] = trunc nuw i32 [[SHR_3]] to i16
; CHECK-NEXT:    br label [[IF_END_3]]
; CHECK:       if.end.3:
; CHECK-NEXT:    [[STOREMERGE_3:%.*]] = phi i16 [ [[CONV28_3]], [[IF_ELSE_3]] ], [ [[CONV12_3]], [[IF_THEN_3]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_3]], ptr [[ARRAYIDX_3]], align 2
; CHECK-NEXT:    [[OR_339:%.*]] = or i16 [[OR_238]], [[STOREMERGE_3]]
; CHECK-NEXT:    [[ARRAYIDX_4:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 8
; CHECK-NEXT:    [[TMP46:%.*]] = load i16, ptr [[ARRAYIDX_4]], align 2
; CHECK-NEXT:    [[CONV_4:%.*]] = sext i16 [[TMP46]] to i32
; CHECK-NEXT:    [[CMP1_4:%.*]] = icmp sgt i16 [[TMP46]], 0
; CHECK-NEXT:    [[ARRAYIDX4_4:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 8
; CHECK-NEXT:    [[TMP47:%.*]] = load i16, ptr [[ARRAYIDX4_4]], align 2
; CHECK-NEXT:    [[CONV5_4:%.*]] = zext i16 [[TMP47]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_4:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 8
; CHECK-NEXT:    [[TMP48:%.*]] = load i16, ptr [[ARRAYIDX10_4]], align 2
; CHECK-NEXT:    [[CONV11_4:%.*]] = zext i16 [[TMP48]] to i32
; CHECK-NEXT:    br i1 [[CMP1_4]], label [[IF_THEN_4:%.*]], label [[IF_ELSE_4:%.*]]
; CHECK:       if.else.4:
; CHECK-NEXT:    [[ADD21_4:%.*]] = sub nsw i32 [[CONV5_4]], [[CONV_4]]
; CHECK-NEXT:    [[MUL25_4:%.*]] = mul i32 [[ADD21_4]], [[CONV11_4]]
; CHECK-NEXT:    [[SHR26_4:%.*]] = lshr i32 [[MUL25_4]], 16
; CHECK-NEXT:    [[TMP49:%.*]] = trunc nuw i32 [[SHR26_4]] to i16
; CHECK-NEXT:    [[CONV28_4:%.*]] = sub i16 0, [[TMP49]]
; CHECK-NEXT:    br label [[IF_END_4:%.*]]
; CHECK:       if.then.4:
; CHECK-NEXT:    [[ADD_4:%.*]] = add nuw nsw i32 [[CONV5_4]], [[CONV_4]]
; CHECK-NEXT:    [[MUL_4:%.*]] = mul i32 [[ADD_4]], [[CONV11_4]]
; CHECK-NEXT:    [[SHR_4:%.*]] = lshr i32 [[MUL_4]], 16
; CHECK-NEXT:    [[CONV12_4:%.*]] = trunc nuw i32 [[SHR_4]] to i16
; CHECK-NEXT:    br label [[IF_END_4]]
; CHECK:       if.end.4:
; CHECK-NEXT:    [[STOREMERGE_4:%.*]] = phi i16 [ [[CONV28_4]], [[IF_ELSE_4]] ], [ [[CONV12_4]], [[IF_THEN_4]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_4]], ptr [[ARRAYIDX_4]], align 2
; CHECK-NEXT:    [[OR_440:%.*]] = or i16 [[OR_339]], [[STOREMERGE_4]]
; CHECK-NEXT:    [[ARRAYIDX_5:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 10
; CHECK-NEXT:    [[TMP50:%.*]] = load i16, ptr [[ARRAYIDX_5]], align 2
; CHECK-NEXT:    [[CONV_5:%.*]] = sext i16 [[TMP50]] to i32
; CHECK-NEXT:    [[CMP1_5:%.*]] = icmp sgt i16 [[TMP50]], 0
; CHECK-NEXT:    [[ARRAYIDX4_5:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 10
; CHECK-NEXT:    [[TMP51:%.*]] = load i16, ptr [[ARRAYIDX4_5]], align 2
; CHECK-NEXT:    [[CONV5_5:%.*]] = zext i16 [[TMP51]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_5:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 10
; CHECK-NEXT:    [[TMP52:%.*]] = load i16, ptr [[ARRAYIDX10_5]], align 2
; CHECK-NEXT:    [[CONV11_5:%.*]] = zext i16 [[TMP52]] to i32
; CHECK-NEXT:    br i1 [[CMP1_5]], label [[IF_THEN_5:%.*]], label [[IF_ELSE_5:%.*]]
; CHECK:       if.else.5:
; CHECK-NEXT:    [[ADD21_5:%.*]] = sub nsw i32 [[CONV5_5]], [[CONV_5]]
; CHECK-NEXT:    [[MUL25_5:%.*]] = mul i32 [[ADD21_5]], [[CONV11_5]]
; CHECK-NEXT:    [[SHR26_5:%.*]] = lshr i32 [[MUL25_5]], 16
; CHECK-NEXT:    [[TMP53:%.*]] = trunc nuw i32 [[SHR26_5]] to i16
; CHECK-NEXT:    [[CONV28_5:%.*]] = sub i16 0, [[TMP53]]
; CHECK-NEXT:    br label [[IF_END_5:%.*]]
; CHECK:       if.then.5:
; CHECK-NEXT:    [[ADD_5:%.*]] = add nuw nsw i32 [[CONV5_5]], [[CONV_5]]
; CHECK-NEXT:    [[MUL_5:%.*]] = mul i32 [[ADD_5]], [[CONV11_5]]
; CHECK-NEXT:    [[SHR_5:%.*]] = lshr i32 [[MUL_5]], 16
; CHECK-NEXT:    [[CONV12_5:%.*]] = trunc nuw i32 [[SHR_5]] to i16
; CHECK-NEXT:    br label [[IF_END_5]]
; CHECK:       if.end.5:
; CHECK-NEXT:    [[STOREMERGE_5:%.*]] = phi i16 [ [[CONV28_5]], [[IF_ELSE_5]] ], [ [[CONV12_5]], [[IF_THEN_5]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_5]], ptr [[ARRAYIDX_5]], align 2
; CHECK-NEXT:    [[OR_541:%.*]] = or i16 [[OR_440]], [[STOREMERGE_5]]
; CHECK-NEXT:    [[ARRAYIDX_6:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 12
; CHECK-NEXT:    [[TMP54:%.*]] = load i16, ptr [[ARRAYIDX_6]], align 2
; CHECK-NEXT:    [[CONV_6:%.*]] = sext i16 [[TMP54]] to i32
; CHECK-NEXT:    [[CMP1_6:%.*]] = icmp sgt i16 [[TMP54]], 0
; CHECK-NEXT:    [[ARRAYIDX4_6:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 12
; CHECK-NEXT:    [[TMP55:%.*]] = load i16, ptr [[ARRAYIDX4_6]], align 2
; CHECK-NEXT:    [[CONV5_6:%.*]] = zext i16 [[TMP55]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_6:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 12
; CHECK-NEXT:    [[TMP56:%.*]] = load i16, ptr [[ARRAYIDX10_6]], align 2
; CHECK-NEXT:    [[CONV11_6:%.*]] = zext i16 [[TMP56]] to i32
; CHECK-NEXT:    br i1 [[CMP1_6]], label [[IF_THEN_6:%.*]], label [[IF_ELSE_6:%.*]]
; CHECK:       if.else.6:
; CHECK-NEXT:    [[ADD21_6:%.*]] = sub nsw i32 [[CONV5_6]], [[CONV_6]]
; CHECK-NEXT:    [[MUL25_6:%.*]] = mul i32 [[ADD21_6]], [[CONV11_6]]
; CHECK-NEXT:    [[SHR26_6:%.*]] = lshr i32 [[MUL25_6]], 16
; CHECK-NEXT:    [[TMP57:%.*]] = trunc nuw i32 [[SHR26_6]] to i16
; CHECK-NEXT:    [[CONV28_6:%.*]] = sub i16 0, [[TMP57]]
; CHECK-NEXT:    br label [[IF_END_6:%.*]]
; CHECK:       if.then.6:
; CHECK-NEXT:    [[ADD_6:%.*]] = add nuw nsw i32 [[CONV5_6]], [[CONV_6]]
; CHECK-NEXT:    [[MUL_6:%.*]] = mul i32 [[ADD_6]], [[CONV11_6]]
; CHECK-NEXT:    [[SHR_6:%.*]] = lshr i32 [[MUL_6]], 16
; CHECK-NEXT:    [[CONV12_6:%.*]] = trunc nuw i32 [[SHR_6]] to i16
; CHECK-NEXT:    br label [[IF_END_6]]
; CHECK:       if.end.6:
; CHECK-NEXT:    [[STOREMERGE_6:%.*]] = phi i16 [ [[CONV28_6]], [[IF_ELSE_6]] ], [ [[CONV12_6]], [[IF_THEN_6]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_6]], ptr [[ARRAYIDX_6]], align 2
; CHECK-NEXT:    [[OR_642:%.*]] = or i16 [[OR_541]], [[STOREMERGE_6]]
; CHECK-NEXT:    [[ARRAYIDX_7:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 14
; CHECK-NEXT:    [[TMP58:%.*]] = load i16, ptr [[ARRAYIDX_7]], align 2
; CHECK-NEXT:    [[CONV_7:%.*]] = sext i16 [[TMP58]] to i32
; CHECK-NEXT:    [[CMP1_7:%.*]] = icmp sgt i16 [[TMP58]], 0
; CHECK-NEXT:    [[ARRAYIDX4_7:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 14
; CHECK-NEXT:    [[TMP59:%.*]] = load i16, ptr [[ARRAYIDX4_7]], align 2
; CHECK-NEXT:    [[CONV5_7:%.*]] = zext i16 [[TMP59]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_7:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 14
; CHECK-NEXT:    [[TMP60:%.*]] = load i16, ptr [[ARRAYIDX10_7]], align 2
; CHECK-NEXT:    [[CONV11_7:%.*]] = zext i16 [[TMP60]] to i32
; CHECK-NEXT:    br i1 [[CMP1_7]], label [[IF_THEN_7:%.*]], label [[IF_ELSE_7:%.*]]
; CHECK:       if.else.7:
; CHECK-NEXT:    [[ADD21_7:%.*]] = sub nsw i32 [[CONV5_7]], [[CONV_7]]
; CHECK-NEXT:    [[MUL25_7:%.*]] = mul i32 [[ADD21_7]], [[CONV11_7]]
; CHECK-NEXT:    [[SHR26_7:%.*]] = lshr i32 [[MUL25_7]], 16
; CHECK-NEXT:    [[TMP61:%.*]] = trunc nuw i32 [[SHR26_7]] to i16
; CHECK-NEXT:    [[CONV28_7:%.*]] = sub i16 0, [[TMP61]]
; CHECK-NEXT:    br label [[IF_END_7:%.*]]
; CHECK:       if.then.7:
; CHECK-NEXT:    [[ADD_7:%.*]] = add nuw nsw i32 [[CONV5_7]], [[CONV_7]]
; CHECK-NEXT:    [[MUL_7:%.*]] = mul i32 [[ADD_7]], [[CONV11_7]]
; CHECK-NEXT:    [[SHR_7:%.*]] = lshr i32 [[MUL_7]], 16
; CHECK-NEXT:    [[CONV12_7:%.*]] = trunc nuw i32 [[SHR_7]] to i16
; CHECK-NEXT:    br label [[IF_END_7]]
; CHECK:       if.end.7:
; CHECK-NEXT:    [[STOREMERGE_7:%.*]] = phi i16 [ [[CONV28_7]], [[IF_ELSE_7]] ], [ [[CONV12_7]], [[IF_THEN_7]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_7]], ptr [[ARRAYIDX_7]], align 2
; CHECK-NEXT:    [[OR_743:%.*]] = or i16 [[OR_642]], [[STOREMERGE_7]]
; CHECK-NEXT:    [[ARRAYIDX_8:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 16
; CHECK-NEXT:    [[TMP62:%.*]] = load i16, ptr [[ARRAYIDX_8]], align 2
; CHECK-NEXT:    [[CONV_8:%.*]] = sext i16 [[TMP62]] to i32
; CHECK-NEXT:    [[CMP1_8:%.*]] = icmp sgt i16 [[TMP62]], 0
; CHECK-NEXT:    [[ARRAYIDX4_8:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 16
; CHECK-NEXT:    [[TMP63:%.*]] = load i16, ptr [[ARRAYIDX4_8]], align 2
; CHECK-NEXT:    [[CONV5_8:%.*]] = zext i16 [[TMP63]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_8:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 16
; CHECK-NEXT:    [[TMP64:%.*]] = load i16, ptr [[ARRAYIDX10_8]], align 2
; CHECK-NEXT:    [[CONV11_8:%.*]] = zext i16 [[TMP64]] to i32
; CHECK-NEXT:    br i1 [[CMP1_8]], label [[IF_THEN_8:%.*]], label [[IF_ELSE_8:%.*]]
; CHECK:       if.else.8:
; CHECK-NEXT:    [[ADD21_8:%.*]] = sub nsw i32 [[CONV5_8]], [[CONV_8]]
; CHECK-NEXT:    [[MUL25_8:%.*]] = mul i32 [[ADD21_8]], [[CONV11_8]]
; CHECK-NEXT:    [[SHR26_8:%.*]] = lshr i32 [[MUL25_8]], 16
; CHECK-NEXT:    [[TMP65:%.*]] = trunc nuw i32 [[SHR26_8]] to i16
; CHECK-NEXT:    [[CONV28_8:%.*]] = sub i16 0, [[TMP65]]
; CHECK-NEXT:    br label [[IF_END_8:%.*]]
; CHECK:       if.then.8:
; CHECK-NEXT:    [[ADD_8:%.*]] = add nuw nsw i32 [[CONV5_8]], [[CONV_8]]
; CHECK-NEXT:    [[MUL_8:%.*]] = mul i32 [[ADD_8]], [[CONV11_8]]
; CHECK-NEXT:    [[SHR_8:%.*]] = lshr i32 [[MUL_8]], 16
; CHECK-NEXT:    [[CONV12_8:%.*]] = trunc nuw i32 [[SHR_8]] to i16
; CHECK-NEXT:    br label [[IF_END_8]]
; CHECK:       if.end.8:
; CHECK-NEXT:    [[STOREMERGE_8:%.*]] = phi i16 [ [[CONV28_8]], [[IF_ELSE_8]] ], [ [[CONV12_8]], [[IF_THEN_8]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_8]], ptr [[ARRAYIDX_8]], align 2
; CHECK-NEXT:    [[OR_844:%.*]] = or i16 [[OR_743]], [[STOREMERGE_8]]
; CHECK-NEXT:    [[ARRAYIDX_9:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 18
; CHECK-NEXT:    [[TMP66:%.*]] = load i16, ptr [[ARRAYIDX_9]], align 2
; CHECK-NEXT:    [[CONV_9:%.*]] = sext i16 [[TMP66]] to i32
; CHECK-NEXT:    [[CMP1_9:%.*]] = icmp sgt i16 [[TMP66]], 0
; CHECK-NEXT:    [[ARRAYIDX4_9:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 18
; CHECK-NEXT:    [[TMP67:%.*]] = load i16, ptr [[ARRAYIDX4_9]], align 2
; CHECK-NEXT:    [[CONV5_9:%.*]] = zext i16 [[TMP67]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_9:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 18
; CHECK-NEXT:    [[TMP68:%.*]] = load i16, ptr [[ARRAYIDX10_9]], align 2
; CHECK-NEXT:    [[CONV11_9:%.*]] = zext i16 [[TMP68]] to i32
; CHECK-NEXT:    br i1 [[CMP1_9]], label [[IF_THEN_9:%.*]], label [[IF_ELSE_9:%.*]]
; CHECK:       if.else.9:
; CHECK-NEXT:    [[ADD21_9:%.*]] = sub nsw i32 [[CONV5_9]], [[CONV_9]]
; CHECK-NEXT:    [[MUL25_9:%.*]] = mul i32 [[ADD21_9]], [[CONV11_9]]
; CHECK-NEXT:    [[SHR26_9:%.*]] = lshr i32 [[MUL25_9]], 16
; CHECK-NEXT:    [[TMP69:%.*]] = trunc nuw i32 [[SHR26_9]] to i16
; CHECK-NEXT:    [[CONV28_9:%.*]] = sub i16 0, [[TMP69]]
; CHECK-NEXT:    br label [[IF_END_9:%.*]]
; CHECK:       if.then.9:
; CHECK-NEXT:    [[ADD_9:%.*]] = add nuw nsw i32 [[CONV5_9]], [[CONV_9]]
; CHECK-NEXT:    [[MUL_9:%.*]] = mul i32 [[ADD_9]], [[CONV11_9]]
; CHECK-NEXT:    [[SHR_9:%.*]] = lshr i32 [[MUL_9]], 16
; CHECK-NEXT:    [[CONV12_9:%.*]] = trunc nuw i32 [[SHR_9]] to i16
; CHECK-NEXT:    br label [[IF_END_9]]
; CHECK:       if.end.9:
; CHECK-NEXT:    [[STOREMERGE_9:%.*]] = phi i16 [ [[CONV28_9]], [[IF_ELSE_9]] ], [ [[CONV12_9]], [[IF_THEN_9]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_9]], ptr [[ARRAYIDX_9]], align 2
; CHECK-NEXT:    [[OR_945:%.*]] = or i16 [[OR_844]], [[STOREMERGE_9]]
; CHECK-NEXT:    [[ARRAYIDX_10:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 20
; CHECK-NEXT:    [[TMP70:%.*]] = load i16, ptr [[ARRAYIDX_10]], align 2
; CHECK-NEXT:    [[CONV_10:%.*]] = sext i16 [[TMP70]] to i32
; CHECK-NEXT:    [[CMP1_10:%.*]] = icmp sgt i16 [[TMP70]], 0
; CHECK-NEXT:    [[ARRAYIDX4_10:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 20
; CHECK-NEXT:    [[TMP71:%.*]] = load i16, ptr [[ARRAYIDX4_10]], align 2
; CHECK-NEXT:    [[CONV5_10:%.*]] = zext i16 [[TMP71]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_10:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 20
; CHECK-NEXT:    [[TMP72:%.*]] = load i16, ptr [[ARRAYIDX10_10]], align 2
; CHECK-NEXT:    [[CONV11_10:%.*]] = zext i16 [[TMP72]] to i32
; CHECK-NEXT:    br i1 [[CMP1_10]], label [[IF_THEN_10:%.*]], label [[IF_ELSE_10:%.*]]
; CHECK:       if.else.10:
; CHECK-NEXT:    [[ADD21_10:%.*]] = sub nsw i32 [[CONV5_10]], [[CONV_10]]
; CHECK-NEXT:    [[MUL25_10:%.*]] = mul i32 [[ADD21_10]], [[CONV11_10]]
; CHECK-NEXT:    [[SHR26_10:%.*]] = lshr i32 [[MUL25_10]], 16
; CHECK-NEXT:    [[TMP73:%.*]] = trunc nuw i32 [[SHR26_10]] to i16
; CHECK-NEXT:    [[CONV28_10:%.*]] = sub i16 0, [[TMP73]]
; CHECK-NEXT:    br label [[IF_END_10:%.*]]
; CHECK:       if.then.10:
; CHECK-NEXT:    [[ADD_10:%.*]] = add nuw nsw i32 [[CONV5_10]], [[CONV_10]]
; CHECK-NEXT:    [[MUL_10:%.*]] = mul i32 [[ADD_10]], [[CONV11_10]]
; CHECK-NEXT:    [[SHR_10:%.*]] = lshr i32 [[MUL_10]], 16
; CHECK-NEXT:    [[CONV12_10:%.*]] = trunc nuw i32 [[SHR_10]] to i16
; CHECK-NEXT:    br label [[IF_END_10]]
; CHECK:       if.end.10:
; CHECK-NEXT:    [[STOREMERGE_10:%.*]] = phi i16 [ [[CONV28_10]], [[IF_ELSE_10]] ], [ [[CONV12_10]], [[IF_THEN_10]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_10]], ptr [[ARRAYIDX_10]], align 2
; CHECK-NEXT:    [[OR_1046:%.*]] = or i16 [[OR_945]], [[STOREMERGE_10]]
; CHECK-NEXT:    [[ARRAYIDX_11:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 22
; CHECK-NEXT:    [[TMP74:%.*]] = load i16, ptr [[ARRAYIDX_11]], align 2
; CHECK-NEXT:    [[CONV_11:%.*]] = sext i16 [[TMP74]] to i32
; CHECK-NEXT:    [[CMP1_11:%.*]] = icmp sgt i16 [[TMP74]], 0
; CHECK-NEXT:    [[ARRAYIDX4_11:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 22
; CHECK-NEXT:    [[TMP75:%.*]] = load i16, ptr [[ARRAYIDX4_11]], align 2
; CHECK-NEXT:    [[CONV5_11:%.*]] = zext i16 [[TMP75]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_11:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 22
; CHECK-NEXT:    [[TMP76:%.*]] = load i16, ptr [[ARRAYIDX10_11]], align 2
; CHECK-NEXT:    [[CONV11_11:%.*]] = zext i16 [[TMP76]] to i32
; CHECK-NEXT:    br i1 [[CMP1_11]], label [[IF_THEN_11:%.*]], label [[IF_ELSE_11:%.*]]
; CHECK:       if.else.11:
; CHECK-NEXT:    [[ADD21_11:%.*]] = sub nsw i32 [[CONV5_11]], [[CONV_11]]
; CHECK-NEXT:    [[MUL25_11:%.*]] = mul i32 [[ADD21_11]], [[CONV11_11]]
; CHECK-NEXT:    [[SHR26_11:%.*]] = lshr i32 [[MUL25_11]], 16
; CHECK-NEXT:    [[TMP77:%.*]] = trunc nuw i32 [[SHR26_11]] to i16
; CHECK-NEXT:    [[CONV28_11:%.*]] = sub i16 0, [[TMP77]]
; CHECK-NEXT:    br label [[IF_END_11:%.*]]
; CHECK:       if.then.11:
; CHECK-NEXT:    [[ADD_11:%.*]] = add nuw nsw i32 [[CONV5_11]], [[CONV_11]]
; CHECK-NEXT:    [[MUL_11:%.*]] = mul i32 [[ADD_11]], [[CONV11_11]]
; CHECK-NEXT:    [[SHR_11:%.*]] = lshr i32 [[MUL_11]], 16
; CHECK-NEXT:    [[CONV12_11:%.*]] = trunc nuw i32 [[SHR_11]] to i16
; CHECK-NEXT:    br label [[IF_END_11]]
; CHECK:       if.end.11:
; CHECK-NEXT:    [[STOREMERGE_11:%.*]] = phi i16 [ [[CONV28_11]], [[IF_ELSE_11]] ], [ [[CONV12_11]], [[IF_THEN_11]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_11]], ptr [[ARRAYIDX_11]], align 2
; CHECK-NEXT:    [[OR_1147:%.*]] = or i16 [[OR_1046]], [[STOREMERGE_11]]
; CHECK-NEXT:    [[ARRAYIDX_12:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 24
; CHECK-NEXT:    [[TMP78:%.*]] = load i16, ptr [[ARRAYIDX_12]], align 2
; CHECK-NEXT:    [[CONV_12:%.*]] = sext i16 [[TMP78]] to i32
; CHECK-NEXT:    [[CMP1_12:%.*]] = icmp sgt i16 [[TMP78]], 0
; CHECK-NEXT:    [[ARRAYIDX4_12:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 24
; CHECK-NEXT:    [[TMP79:%.*]] = load i16, ptr [[ARRAYIDX4_12]], align 2
; CHECK-NEXT:    [[CONV5_12:%.*]] = zext i16 [[TMP79]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_12:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 24
; CHECK-NEXT:    [[TMP80:%.*]] = load i16, ptr [[ARRAYIDX10_12]], align 2
; CHECK-NEXT:    [[CONV11_12:%.*]] = zext i16 [[TMP80]] to i32
; CHECK-NEXT:    br i1 [[CMP1_12]], label [[IF_THEN_12:%.*]], label [[IF_ELSE_12:%.*]]
; CHECK:       if.else.12:
; CHECK-NEXT:    [[ADD21_12:%.*]] = sub nsw i32 [[CONV5_12]], [[CONV_12]]
; CHECK-NEXT:    [[MUL25_12:%.*]] = mul i32 [[ADD21_12]], [[CONV11_12]]
; CHECK-NEXT:    [[SHR26_12:%.*]] = lshr i32 [[MUL25_12]], 16
; CHECK-NEXT:    [[TMP81:%.*]] = trunc nuw i32 [[SHR26_12]] to i16
; CHECK-NEXT:    [[CONV28_12:%.*]] = sub i16 0, [[TMP81]]
; CHECK-NEXT:    br label [[IF_END_12:%.*]]
; CHECK:       if.then.12:
; CHECK-NEXT:    [[ADD_12:%.*]] = add nuw nsw i32 [[CONV5_12]], [[CONV_12]]
; CHECK-NEXT:    [[MUL_12:%.*]] = mul i32 [[ADD_12]], [[CONV11_12]]
; CHECK-NEXT:    [[SHR_12:%.*]] = lshr i32 [[MUL_12]], 16
; CHECK-NEXT:    [[CONV12_12:%.*]] = trunc nuw i32 [[SHR_12]] to i16
; CHECK-NEXT:    br label [[IF_END_12]]
; CHECK:       if.end.12:
; CHECK-NEXT:    [[STOREMERGE_12:%.*]] = phi i16 [ [[CONV28_12]], [[IF_ELSE_12]] ], [ [[CONV12_12]], [[IF_THEN_12]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_12]], ptr [[ARRAYIDX_12]], align 2
; CHECK-NEXT:    [[OR_1248:%.*]] = or i16 [[OR_1147]], [[STOREMERGE_12]]
; CHECK-NEXT:    [[ARRAYIDX_13:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 26
; CHECK-NEXT:    [[TMP82:%.*]] = load i16, ptr [[ARRAYIDX_13]], align 2
; CHECK-NEXT:    [[CONV_13:%.*]] = sext i16 [[TMP82]] to i32
; CHECK-NEXT:    [[CMP1_13:%.*]] = icmp sgt i16 [[TMP82]], 0
; CHECK-NEXT:    [[ARRAYIDX4_13:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 26
; CHECK-NEXT:    [[TMP83:%.*]] = load i16, ptr [[ARRAYIDX4_13]], align 2
; CHECK-NEXT:    [[CONV5_13:%.*]] = zext i16 [[TMP83]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_13:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 26
; CHECK-NEXT:    [[TMP84:%.*]] = load i16, ptr [[ARRAYIDX10_13]], align 2
; CHECK-NEXT:    [[CONV11_13:%.*]] = zext i16 [[TMP84]] to i32
; CHECK-NEXT:    br i1 [[CMP1_13]], label [[IF_THEN_13:%.*]], label [[IF_ELSE_13:%.*]]
; CHECK:       if.else.13:
; CHECK-NEXT:    [[ADD21_13:%.*]] = sub nsw i32 [[CONV5_13]], [[CONV_13]]
; CHECK-NEXT:    [[MUL25_13:%.*]] = mul i32 [[ADD21_13]], [[CONV11_13]]
; CHECK-NEXT:    [[SHR26_13:%.*]] = lshr i32 [[MUL25_13]], 16
; CHECK-NEXT:    [[TMP85:%.*]] = trunc nuw i32 [[SHR26_13]] to i16
; CHECK-NEXT:    [[CONV28_13:%.*]] = sub i16 0, [[TMP85]]
; CHECK-NEXT:    br label [[IF_END_13:%.*]]
; CHECK:       if.then.13:
; CHECK-NEXT:    [[ADD_13:%.*]] = add nuw nsw i32 [[CONV5_13]], [[CONV_13]]
; CHECK-NEXT:    [[MUL_13:%.*]] = mul i32 [[ADD_13]], [[CONV11_13]]
; CHECK-NEXT:    [[SHR_13:%.*]] = lshr i32 [[MUL_13]], 16
; CHECK-NEXT:    [[CONV12_13:%.*]] = trunc nuw i32 [[SHR_13]] to i16
; CHECK-NEXT:    br label [[IF_END_13]]
; CHECK:       if.end.13:
; CHECK-NEXT:    [[STOREMERGE_13:%.*]] = phi i16 [ [[CONV28_13]], [[IF_ELSE_13]] ], [ [[CONV12_13]], [[IF_THEN_13]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_13]], ptr [[ARRAYIDX_13]], align 2
; CHECK-NEXT:    [[OR_1349:%.*]] = or i16 [[OR_1248]], [[STOREMERGE_13]]
; CHECK-NEXT:    [[ARRAYIDX_14:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 28
; CHECK-NEXT:    [[TMP86:%.*]] = load i16, ptr [[ARRAYIDX_14]], align 2
; CHECK-NEXT:    [[CONV_14:%.*]] = sext i16 [[TMP86]] to i32
; CHECK-NEXT:    [[CMP1_14:%.*]] = icmp sgt i16 [[TMP86]], 0
; CHECK-NEXT:    [[ARRAYIDX4_14:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 28
; CHECK-NEXT:    [[TMP87:%.*]] = load i16, ptr [[ARRAYIDX4_14]], align 2
; CHECK-NEXT:    [[CONV5_14:%.*]] = zext i16 [[TMP87]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_14:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 28
; CHECK-NEXT:    [[TMP88:%.*]] = load i16, ptr [[ARRAYIDX10_14]], align 2
; CHECK-NEXT:    [[CONV11_14:%.*]] = zext i16 [[TMP88]] to i32
; CHECK-NEXT:    br i1 [[CMP1_14]], label [[IF_THEN_14:%.*]], label [[IF_ELSE_14:%.*]]
; CHECK:       if.else.14:
; CHECK-NEXT:    [[ADD21_14:%.*]] = sub nsw i32 [[CONV5_14]], [[CONV_14]]
; CHECK-NEXT:    [[MUL25_14:%.*]] = mul i32 [[ADD21_14]], [[CONV11_14]]
; CHECK-NEXT:    [[SHR26_14:%.*]] = lshr i32 [[MUL25_14]], 16
; CHECK-NEXT:    [[TMP89:%.*]] = trunc nuw i32 [[SHR26_14]] to i16
; CHECK-NEXT:    [[CONV28_14:%.*]] = sub i16 0, [[TMP89]]
; CHECK-NEXT:    br label [[IF_END_14:%.*]]
; CHECK:       if.then.14:
; CHECK-NEXT:    [[ADD_14:%.*]] = add nuw nsw i32 [[CONV5_14]], [[CONV_14]]
; CHECK-NEXT:    [[MUL_14:%.*]] = mul i32 [[ADD_14]], [[CONV11_14]]
; CHECK-NEXT:    [[SHR_14:%.*]] = lshr i32 [[MUL_14]], 16
; CHECK-NEXT:    [[CONV12_14:%.*]] = trunc nuw i32 [[SHR_14]] to i16
; CHECK-NEXT:    br label [[IF_END_14]]
; CHECK:       if.end.14:
; CHECK-NEXT:    [[STOREMERGE_14:%.*]] = phi i16 [ [[CONV28_14]], [[IF_ELSE_14]] ], [ [[CONV12_14]], [[IF_THEN_14]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_14]], ptr [[ARRAYIDX_14]], align 2
; CHECK-NEXT:    [[OR_1450:%.*]] = or i16 [[OR_1349]], [[STOREMERGE_14]]
; CHECK-NEXT:    [[ARRAYIDX_15:%.*]] = getelementptr inbounds nuw i8, ptr [[DCT]], i64 30
; CHECK-NEXT:    [[TMP90:%.*]] = load i16, ptr [[ARRAYIDX_15]], align 2
; CHECK-NEXT:    [[CONV_15:%.*]] = sext i16 [[TMP90]] to i32
; CHECK-NEXT:    [[CMP1_15:%.*]] = icmp sgt i16 [[TMP90]], 0
; CHECK-NEXT:    [[ARRAYIDX4_15:%.*]] = getelementptr inbounds nuw i8, ptr [[BIAS]], i64 30
; CHECK-NEXT:    [[TMP91:%.*]] = load i16, ptr [[ARRAYIDX4_15]], align 2
; CHECK-NEXT:    [[CONV5_15:%.*]] = zext i16 [[TMP91]] to i32
; CHECK-NEXT:    [[ARRAYIDX10_15:%.*]] = getelementptr inbounds nuw i8, ptr [[MF]], i64 30
; CHECK-NEXT:    [[TMP92:%.*]] = load i16, ptr [[ARRAYIDX10_15]], align 2
; CHECK-NEXT:    [[CONV11_15:%.*]] = zext i16 [[TMP92]] to i32
; CHECK-NEXT:    br i1 [[CMP1_15]], label [[IF_THEN_15:%.*]], label [[IF_ELSE_15:%.*]]
; CHECK:       if.else.15:
; CHECK-NEXT:    [[ADD21_15:%.*]] = sub nsw i32 [[CONV5_15]], [[CONV_15]]
; CHECK-NEXT:    [[MUL25_15:%.*]] = mul i32 [[ADD21_15]], [[CONV11_15]]
; CHECK-NEXT:    [[SHR26_15:%.*]] = lshr i32 [[MUL25_15]], 16
; CHECK-NEXT:    [[TMP93:%.*]] = trunc nuw i32 [[SHR26_15]] to i16
; CHECK-NEXT:    [[CONV28_15:%.*]] = sub i16 0, [[TMP93]]
; CHECK-NEXT:    br label [[IF_END_15]]
; CHECK:       if.then.15:
; CHECK-NEXT:    [[ADD_15:%.*]] = add nuw nsw i32 [[CONV5_15]], [[CONV_15]]
; CHECK-NEXT:    [[MUL_15:%.*]] = mul i32 [[ADD_15]], [[CONV11_15]]
; CHECK-NEXT:    [[SHR_15:%.*]] = lshr i32 [[MUL_15]], 16
; CHECK-NEXT:    [[CONV12_15:%.*]] = trunc nuw i32 [[SHR_15]] to i16
; CHECK-NEXT:    br label [[IF_END_15]]
; CHECK:       if.end.15:
; CHECK-NEXT:    [[STOREMERGE_15:%.*]] = phi i16 [ [[CONV28_15]], [[IF_ELSE_15]] ], [ [[CONV12_15]], [[IF_THEN_15]] ]
; CHECK-NEXT:    store i16 [[STOREMERGE_15]], ptr [[ARRAYIDX_15]], align 2
; CHECK-NEXT:    [[OR_1551]] = or i16 [[OR_1450]], [[STOREMERGE_15]]
; CHECK-NEXT:    br label [[FOR_COND_CLEANUP]]
;
entry:
  %dct.addr = alloca ptr, align 8
  %mf.addr = alloca ptr, align 8
  %bias.addr = alloca ptr, align 8
  %nz = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %dct, ptr %dct.addr, align 8
  store ptr %mf, ptr %mf.addr, align 8
  store ptr %bias, ptr %bias.addr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr %nz) #2
  store i32 0, ptr %nz, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr %i) #2
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4
  %cmp = icmp slt i32 %0, 16
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  call void @llvm.lifetime.end.p0(i64 4, ptr %i) #2
  br label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load ptr, ptr %dct.addr, align 8
  %2 = load i32, ptr %i, align 4
  %idxprom = sext i32 %2 to i64
  %arrayidx = getelementptr inbounds i16, ptr %1, i64 %idxprom
  %3 = load i16, ptr %arrayidx, align 2
  %conv = sext i16 %3 to i32
  %cmp1 = icmp sgt i32 %conv, 0
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %for.body
  %4 = load ptr, ptr %bias.addr, align 8
  %5 = load i32, ptr %i, align 4
  %idxprom3 = sext i32 %5 to i64
  %arrayidx4 = getelementptr inbounds i16, ptr %4, i64 %idxprom3
  %6 = load i16, ptr %arrayidx4, align 2
  %conv5 = zext i16 %6 to i32
  %7 = load ptr, ptr %dct.addr, align 8
  %8 = load i32, ptr %i, align 4
  %idxprom6 = sext i32 %8 to i64
  %arrayidx7 = getelementptr inbounds i16, ptr %7, i64 %idxprom6
  %9 = load i16, ptr %arrayidx7, align 2
  %conv8 = sext i16 %9 to i32
  %add = add i32 %conv5, %conv8
  %10 = load ptr, ptr %mf.addr, align 8
  %11 = load i32, ptr %i, align 4
  %idxprom9 = sext i32 %11 to i64
  %arrayidx10 = getelementptr inbounds i16, ptr %10, i64 %idxprom9
  %12 = load i16, ptr %arrayidx10, align 2
  %conv11 = zext i16 %12 to i32
  %mul = mul i32 %add, %conv11
  %shr = lshr i32 %mul, 16
  %conv12 = trunc i32 %shr to i16
  %13 = load ptr, ptr %dct.addr, align 8
  %14 = load i32, ptr %i, align 4
  %idxprom13 = sext i32 %14 to i64
  %arrayidx14 = getelementptr inbounds i16, ptr %13, i64 %idxprom13
  store i16 %conv12, ptr %arrayidx14, align 2
  br label %if.end

if.else:                                          ; preds = %for.body
  %15 = load ptr, ptr %bias.addr, align 8
  %16 = load i32, ptr %i, align 4
  %idxprom15 = sext i32 %16 to i64
  %arrayidx16 = getelementptr inbounds i16, ptr %15, i64 %idxprom15
  %17 = load i16, ptr %arrayidx16, align 2
  %conv17 = zext i16 %17 to i32
  %18 = load ptr, ptr %dct.addr, align 8
  %19 = load i32, ptr %i, align 4
  %idxprom18 = sext i32 %19 to i64
  %arrayidx19 = getelementptr inbounds i16, ptr %18, i64 %idxprom18
  %20 = load i16, ptr %arrayidx19, align 2
  %conv20 = sext i16 %20 to i32
  %sub = sub nsw i32 0, %conv20
  %add21 = add i32 %conv17, %sub
  %21 = load ptr, ptr %mf.addr, align 8
  %22 = load i32, ptr %i, align 4
  %idxprom22 = sext i32 %22 to i64
  %arrayidx23 = getelementptr inbounds i16, ptr %21, i64 %idxprom22
  %23 = load i16, ptr %arrayidx23, align 2
  %conv24 = zext i16 %23 to i32
  %mul25 = mul i32 %add21, %conv24
  %shr26 = lshr i32 %mul25, 16
  %sub27 = sub nsw i32 0, %shr26
  %conv28 = trunc i32 %sub27 to i16
  %24 = load ptr, ptr %dct.addr, align 8
  %25 = load i32, ptr %i, align 4
  %idxprom29 = sext i32 %25 to i64
  %arrayidx30 = getelementptr inbounds i16, ptr %24, i64 %idxprom29
  store i16 %conv28, ptr %arrayidx30, align 2
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %26 = load ptr, ptr %dct.addr, align 8
  %27 = load i32, ptr %i, align 4
  %idxprom31 = sext i32 %27 to i64
  %arrayidx32 = getelementptr inbounds i16, ptr %26, i64 %idxprom31
  %28 = load i16, ptr %arrayidx32, align 2
  %conv33 = sext i16 %28 to i32
  %29 = load i32, ptr %nz, align 4
  %or = or i32 %29, %conv33
  store i32 %or, ptr %nz, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %30 = load i32, ptr %i, align 4
  %inc = add nsw i32 %30, 1
  store i32 %inc, ptr %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  %31 = load i32, ptr %nz, align 4
  %tobool = icmp ne i32 %31, 0
  %lnot = xor i1 %tobool, true
  %lnot34 = xor i1 %lnot, true
  %lnot.ext = zext i1 %lnot34 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr %nz) #2
  ret i32 %lnot.ext
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

