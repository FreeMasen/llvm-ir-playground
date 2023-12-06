%Rng = type { i32, i32, i32 }

define i32 @rng_size() {
    %size_ptr = getelementptr [1 x %Rng], ptr null, i32 1
    %size = ptrtoint ptr %size_ptr to i32
    ret i32 %size
}

define void @init_rng(ptr %rng, i32 %seed) {
entry:
  %seed_ptr = getelementptr %Rng, ptr %rng, i32 0, i32 0
  store i32 %seed, ptr %seed_ptr
  %w_ptr = getelementptr %Rng, ptr %rng, i32 0, i32 1
  store i32 0, ptr %w_ptr
  %x_ptr = getelementptr %Rng, ptr %rng, i32 0, i32 2
  store i32 0, ptr %x_ptr
  ret void
}

define i32 @rng_next(ptr %rng) {
entry:
  %seed_ptr = getelementptr %Rng, ptr %rng, i32 0, i32 0
  %seed = load i32, ptr %seed_ptr
  %w_ptr = getelementptr %Rng, ptr %rng, i32 0, i32 1
  %w = load i32, ptr %w_ptr
  %x_ptr = getelementptr %Rng, ptr %rng, i32 0, i32 2
  %x = load i32, ptr %x_ptr
  %w2 = add i32 %w, %seed
  %x2 = mul i32 %x, %x
  %x3 = add i32 %w2, %w2
  store i32 %x3, ptr %x_ptr
  store i32 %w2, ptr %w_ptr
  %ret1 = lshr i32 %x3, 4
  %ret2 = shl i32 %w2, 4
  %ret = or i32 %ret1, %ret2
  ret i32 %ret
}
