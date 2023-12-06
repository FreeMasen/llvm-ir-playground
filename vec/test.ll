declare void @vec_init(ptr %vec, i32 %el_size)
declare void @vec_init_with_capacity(ptr %vec, i32 %el_size, i32)
declare i32 @vec_len(ptr %vec)
declare void @vec_set_len(ptr %vec, i32 %len)
declare void @vec_set_capacity(ptr %vec, i32 %len)
declare i32 @vec_el_size(ptr %vec)
declare i32 @vec_capacity(ptr %vec)
declare void @vec_bump_capacity(ptr %vec)
declare void @vec_push(ptr %vec, ptr %element)
declare ptr @vec_get(ptr %vec, i32 %idx)
declare ptr @vec_remove(ptr %vec, i32 %idx)
declare i32 @vec_size()

declare void @llvm.trap()

define void @push_and_print(ptr %vec, i32 %v) {
entry:
    %fmt = alloca [255 x i8]
    store [ 13 x i8 ] c"pushing: %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %v)
    %el = alloca i32
    store i32 %v, ptr %el
    call void @vec_push(ptr %vec, ptr %el)
    store [ 25 x i8 ] c"pushed: %u, new_cap: %u\0A\00", ptr %fmt
    %len = call i32 @vec_len(ptr %vec)
    %cap = call i32 @vec_capacity(ptr %vec)
    call i32 @printf(ptr %fmt, i32 %len, i32 %cap)
    ret void
}

define void @lookup_and_print(ptr %vec, i32 %idx) {
entry:
    %fmt = alloca [255 x i8]
    %ptr = call ptr @vec_get(ptr %vec, i32 %idx)
    %el = load i32, ptr %ptr
    store [ 25 x i8 ] c"looked up: vec[%u] = %u\0A\00", ptr %fmt
    %len = call i32 @vec_len(ptr %vec)
    call i32 @printf(ptr %fmt, i32 %idx, i32 %el, i32 %len)
    ret void
}

define void @remove_and_print(ptr %vec, i32 %idx) {
entry:
    %fmt = alloca [255 x i8]
    %ptr = alloca i32
    %success = call i1 @vec_remove(ptr %vec, ptr %ptr, i32 %idx)
    br i1 %success, label %exit, label %err
err:
    store [24 x i8] c"index out of range: %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %idx)
    call void @llvm.trap()
    ret void
exit:
    %el = load i32, ptr %ptr
    %len = call i32 @vec_len(ptr %vec)
    store [ 35 x i8 ] c"removed: vec[%u] = %u new len: %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %idx, i32 %el, i32 %len)
    ret void
}

define void @push_loop(ptr %vec, i32 %count) {
entry:
    br label %looptop
looptop:
    %i = phi i32 [0, %entry], [%next_i, %loopbody]
    %done = icmp uge i32 %i, %count
    br i1 %done, label %loopexit, label %loopbody
loopbody:
    %next_i = add i32 %i, 1
    call void @push_and_print(ptr %vec, i32 %i)
    br label %looptop
loopexit:
    ret void
}

define void @get_loop(ptr %vec, i32 %count) {
entry:
    br label %looptop
looptop:
    %i = phi i32 [0, %entry], [%next_i, %loopbody]
    %done = icmp uge i32 %i, %count
    br i1 %done, label %loopexit, label %loopbody
loopbody:
    %next_i = add i32 %i, 1
    call void @lookup_and_print(ptr %vec, i32 %i)
    br label %looptop
loopexit:
    ret void
}

define void @remove_loop(ptr %vec, i32 %count) {
entry:
    br label %looptop
looptop:
    %i = phi i32 [0, %entry], [%next_i, %loopbody]
    %done = icmp uge i32 %i, %count
    br i1 %done, label %loopexit, label %loopbody
loopbody:
    %next_i = add i32 %i, 1
    call void @remove_and_print(ptr %vec, i32 0)
    br label %looptop
loopexit:
    ret void
}

define i32 @main(i32 %argc, ptr %arv) {
entry:
    %fmt = alloca [255 x i8]
    %vec_size = call i32 @vec_size()
    %v = alloca i8, i32 %vec_size
    call void @vec_init(ptr %v, i32 4)
    call void @push_and_print(ptr %v, i32 1)
    call void @lookup_and_print(ptr %v, i32 0)
    call void @push_and_print(ptr %v, i32 2)
    call void @push_and_print(ptr %v, i32 3)
    call void @lookup_and_print(ptr %v, i32 0)
    call void @lookup_and_print(ptr %v, i32 1)
    call void @lookup_and_print(ptr %v, i32 2)
    call void @remove_and_print(ptr %v, i32 2)
    call void @remove_and_print(ptr %v, i32 1)
    call void @remove_and_print(ptr %v, i32 0)

    %v2 = alloca i8, i32 %vec_size
    call void @vec_init_with_capacity(ptr %v2, i32 4, i32 10)
    call void @push_loop(ptr %v2, i32 100)
    call void @get_loop(ptr %v2, i32 100)
    call void @remove_loop(ptr %v2, i32 100)
    ret i32 0
}

declare i32 @printf(ptr, ...)
