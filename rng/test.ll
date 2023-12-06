declare i32 @rng_size()
declare void @init_rng(ptr %rng, i32 %seed)
declare i32 @rng_next(ptr %rng)

declare i32 @printf(ptr, ...)
declare void @llvm.trap()

define void @generate_sequence(ptr %rng, i32 %max) {
entry:
  %fmt = alloca [ 255 x i8 ]
  store [2 x i8] c"[\00", ptr %fmt
  call i32 @printf(ptr %fmt)
  br label %looptop
looptop:
  %idx = phi i32 [0, %entry], [%next, %loopbottom]
  %done = icmp ugt i32 %idx, %max
  br i1 %done, label %exit, label %loopbody
loopbody:
  %gtz = icmp ugt i32 %idx, 0
  br i1 %gtz, label %comma, label %loopbottom
comma:
  store [ 2 x i8 ] c",\00", ptr %fmt
  call i32 @printf(ptr %fmt)
  br label %loopbottom
loopbottom:
  %v = call i32 @rng_next(ptr %rng)
  store [ 3 x i8 ] c"%u\00", ptr %fmt
  call i32 @printf(ptr %fmt, i32 %v)
  %next = add i32 %idx, 1
  br label %looptop
exit:
  store [3 x i8] c"]\0A\00", ptr %fmt
  call i32 @printf(ptr %fmt)
  ret void
}

define i32 @main() {
entry:
  %rng_size = call i32 @rng_size()
  %rng = alloca i8, i32 %rng_size
  br label %looptop
looptop:
  %idx = phi i32 [0, %entry], [%next, %loopbody]
  %done = icmp uge i32 %idx, 31
  br i1 %done, label %loopexit, label %loopbody
loopbody:
  %seed = shl i32 1, %idx
  call void @init_rng(ptr %rng, i32 %seed)
  call void @generate_sequence(ptr %rng, i32 25)
  %next = add i32 %idx, 1
  br label %looptop
loopexit:
  ret i32 0
}
