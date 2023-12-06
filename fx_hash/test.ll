
define void @printi(i32 %i) {
    %fmt = alloca [4 x i8]
    store [4 x i8] c"%u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %i)
    ret void
}

declare i32 @printf(ptr, ...)

define void @hash_hw(ptr %hasher) {
entry:
    %hw = alloca [13 x i8]
    store [13 x i8] c"Hello, world!", ptr %hw
    call void @fx_hasher_write(ptr %hasher, ptr %hw, i32 13)
    ret void
}

define void @do_numbers(ptr %hasher) {
entry:
    call void @fx_hasher_write_u8(ptr %hasher, i8 255)
    call void @fx_hasher_write_u32(ptr %hasher, i32 999999)
    call void @fx_hasher_write_u64(ptr %hasher, i64 99999999)
    ret void
}

define i32 @main(i32 %argc, i8** %argv) {
entry:
    %arg1 = icmp ugt i32 %argc, 1
    %hasher_size = call i32 @fx_hasher_size()
    %hasher = alloca i8, i32 %hasher_size
    call void @fx_hasher_init(ptr %hasher)
    br i1 %arg1, label %text, label %nums
nums:
    call void @do_numbers(ptr %hasher)
    br label %end
text:
    %arg = getelementptr inbounds ptr, ptr %argv, i32 1
    %arg2 = load ptr, ptr %arg
    %arg_len = call i32 @strlen(ptr %arg2)
    call void @fx_hasher_write(ptr %hasher, ptr %arg2, i32 %arg_len)
    
    br label %end
end:
    %v = call i32 @fx_hasher_get_value(ptr %hasher)
    call void @printi(i32 %v)
    ret i32 0
}

declare void @fx_hasher_write_u32(ptr %hasher, i32 %v)
declare void @fx_hasher_write_u8(ptr %hasher, i8 %v)
declare void @fx_hasher_write_u64(ptr %hasher, i64 %v)
declare i64 @fx_hasher_get_value(ptr %hasher)
declare i32 @fx_hasher_write_step(ptr %hasher, ptr %buf, i32 %len)
declare void @fx_hasher_write(ptr %hasher, ptr %buf, i32 %len)
declare void @fx_hasher_init(ptr %hasher)
declare i32 @fx_hasher_size()
declare i32 @strlen(ptr)
