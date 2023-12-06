
declare void @sparse_array_init(ptr, i32, i32)
declare i32 @sparse_array_capacity(ptr)
declare i1 @sparse_array_push(ptr, ptr)
declare ptr @sparse_array_get(ptr, i32)
declare i1 @sparse_array_is_set(ptr, i32)
declare i1 @sparse_array_remove(ptr, ptr, i32)
declare i32 @sparse_array_next_vacant(ptr)
declare void @llvm.trap()
declare i32 @printf(ptr, ...)
declare i32 @sparse_array_size()



define void @print_sparse_array(ptr %sa) {
entry:
    %fmt = alloca [255 x i8]
    %cap = call i32 @sparse_array_capacity(ptr %sa)
    store [ 2 x i8 ] c"[\00", ptr %fmt
    call i32 @printf(ptr %fmt)
    br label %looptop
looptop:
    %idx = phi i32 [0, %entry], [%next_idx, %loopbottom]
    %done = icmp uge i32 %idx, %cap
    br i1 %done, label %exit, label %loopbody
loopbody:
    %should_comma = icmp ugt i32 %idx, 0
    br i1 %should_comma, label %after1, label %check
after1:
    store [ 2 x i8] c",\00", ptr %fmt
    call i32 @printf(ptr %fmt)
    br label %check
check:
    %is_full = call i1 @sparse_array_is_set(ptr %sa, i32 %idx)
    br i1 %is_full, label %pop, label %unpop
pop:
    store [5 x i8] c"% 3u\00", ptr %fmt
    %el_ptr = call ptr @sparse_array_get(ptr %sa, i32 %idx)
    %v = load i32, ptr %el_ptr
    call i32 @printf(ptr %fmt, i32 %v)
    br label %loopbottom
unpop:
    store [4 x i8] c"---\00", ptr %fmt
    call i32 @printf(ptr %fmt)
    br label %loopbottom
loopbottom:
    %next_idx = add i32 %idx, 1
    br label %looptop
exit:
    store [ 3 x i8 ] c"]\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt)
    ret void
}

define void @fill_sa(ptr %sa) {
entry:
    %fmt = alloca [255 x i8]
    br label %looptop
looptop:
    %idx = phi i32 [0, %entry], [%next_idx, %loopbody]
    %done = icmp uge i32 %idx, 32
    br i1 %done, label %exit, label %loopbody
loopbody:
    %el = alloca i32
    store i32 %idx, ptr %el
    %succ = call i1 @sparse_array_push(ptr %sa, ptr %el)
    call void @print_sparse_array(ptr %sa)
    %ptr = call ptr @sparse_array_get(ptr %sa, i32 %idx)
    %val = load i32, ptr %ptr
    %is_val = icmp eq i32 %idx, %val
    %succ2 = and i1 %succ, %is_val
    %next_idx = add i32 %idx, 1
    br i1 %succ2, label %looptop, label %fail
fail:
    store [37 x i8] c"Error inserting element at index %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %idx)
    call void @llvm.trap()
    br label %exit
exit:
    ret void
}

define void @sparse_up(ptr %sa) {
entry:
    %fmt = alloca [255 x i8]
    br label %looptop
looptop:
    %idx = phi i32 [24, %entry], [%next_idx, %loopbody]
    %done = icmp slt i32 %idx, 0
    br i1 %done, label %exit, label %loopbody
loopbody:
    %el = alloca i32    
    %succ = call i1 @sparse_array_remove(ptr %sa, ptr %el, i32 %idx)
    call void @print_sparse_array(ptr %sa)
    %v = load i32, ptr %el
    %next_free = call i32 @sparse_array_next_vacant(ptr %sa)
    %next_idx = sub i32 %idx, 8
    br i1 %succ, label %looptop, label %fail
fail:
    store [36 x i8] c"Error removing element at index %u\0A\00", ptr %fmt
    call i32 @printf(ptr %fmt, i32 %idx)
    call void @llvm.trap()
    br label %exit
exit:
    ret void
}


define i32 @main(i32 %argc, ptr %arv) {
entry:
    %fmt = alloca [255 x i8]
    %sa_size = call i32 @sparse_array_size()
    %sa = alloca i8, i32 %sa_size
    call void @sparse_array_init(ptr %sa, i32 4, i32 32)
    call void @fill_sa(ptr %sa)
    call void @sparse_up(ptr %sa)
    %v = alloca i32
    store i32 999, ptr %v
    call i1 @sparse_array_push(ptr %sa, ptr %v)
    call void @print_sparse_array(ptr %sa)
    ret i32 0
}
