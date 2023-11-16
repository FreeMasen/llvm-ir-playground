declare void @vec_init(ptr %vec, i32 %el_size)
declare i32 @vec_len(ptr %vec)
declare void @vec_set_len(ptr %vec, i32 %len)
declare void @vec_set_capacity(ptr %vec, i32 %len)
declare i32 @vec_el_size(ptr %vec)
declare i32 @vec_capacity(ptr %vec)
declare void @vec_bump_capacity(ptr %vec)
declare void @vec_push(ptr %vec, ptr %element)
declare ptr @vec_get(ptr %vec, i32 %idx)
%Slice = type { i32, ptr }
%Vec = type { i32, i32, %Slice }

define void @push_and_print(ptr %vec, i32 %v) {
entry:
    %fmt = alloca [255 x i8]
    store [ 13 x i8 ] c"pushing: %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %v)
    %el = alloca i32
    store i32 %v, ptr %el
    call void @vec_push(ptr %vec, ptr %el)
    store [ 12 x i8 ] c"pushed: %u\0A\00", ptr %fmt
    %len = call i32 @vec_len(ptr %vec)
    call i32 @printf(ptr %fmt, i32 %len)
    ret void
}

define void @lookup_and_print(ptr %vec, i32 %idx) {
entry:
    %fmt = alloca [255 x i8]
    %ptr = call ptr @vec_get(ptr %vec, i32 %idx)
    %el = load i32, ptr %ptr
    store [ 25 x i8 ] c"looked up: vec[%u] = %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %idx, i32 %el)
    ret void
}

define i32 @main() {
    %fmt = alloca [255 x i8]
    %v = alloca %Vec
    call void @vec_init(ptr %v, i32 4)
    call void @push_and_print(ptr %v, i32 1)
    call void @lookup_and_print(ptr %v, i32 0)
    call void @push_and_print(ptr %v, i32 2)
    call void @push_and_print(ptr %v, i32 3)
    call void @lookup_and_print(ptr %v, i32 1)
    call void @lookup_and_print(ptr %v, i32 2)
    ret i32 0
}

declare i32 @printf(ptr, ...)
