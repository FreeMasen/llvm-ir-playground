%FxHasher = type { i32 }

define void @printi(i32 %i) {
    %fmt = alloca [4 x i8]
    store [4 x i8] c"%u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %i)
    ret void
}

declare i32 @printf(ptr, ...)

define i32 @main() {
entry:
    %hasher = alloca %FxHasher
    call void @fx_hasher_init(ptr %hasher)
    %hw = alloca [13 x i8]
    store [13 x i8] c"Hello, world!", ptr %hw
    call void @fx_hasher_write(ptr %hasher, ptr %hw, i32 13)
    %hash = call i64 @fx_hasher_get_value(ptr %hasher)
    call void @printi(i64 %hash)
    ret i32 0
}

declare void @fx_hasher_hash_word(ptr %hasher, i32 %v)
declare void @fx_hasher_write_u8(ptr %hasher, i8 %v)
declare void @fx_hasher_write_u64(ptr %hasher, i64 %v)
declare i64 @fx_hasher_get_value(ptr %hasher)
declare i32 @fx_hasher_write_step(ptr %hasher, ptr %buf, i32 %len)
declare void @fx_hasher_write(ptr %hasher, ptr %buf, i32 %len)
declare void @fx_hasher_init(ptr %hasher)
