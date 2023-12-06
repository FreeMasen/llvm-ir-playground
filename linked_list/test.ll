
define void @print_i(i32 %v) {
  %fmt = alloca [255 x i8]
  store [4 x i8] c"%i\0A\00", ptr %fmt
  call i32 @printf(ptr %fmt, i32 %v)
  ret void
}

define void @print_ll(ptr %ll) {
entry:
  %fmt = alloca [ 7 x i8 ]
  store [ 2 x i8 ] c"[\00", ptr %fmt
  call i32 @printf(ptr %fmt)
  store [ 5 x i8 ] c"|%u|\00", ptr %fmt
  %start = call ptr @linked_list_front(ptr %ll)
  %nil = icmp eq ptr %start, null
  br i1 %nil, label %exit, label %looptop
looptop:
  %node = phi ptr [%start, %entry], [%next, %arrow]
  br label %loopbody
loopbody:
  %v_ptr = call ptr @link_value(ptr %node)
  %v = load i32, ptr %v_ptr
  call i32 @printf(ptr %fmt, i32 %v)
  %next = call ptr @link_next(ptr %node)
  %done = icmp eq ptr %next, null
  br i1 %done, label %exit, label %arrow
arrow:
  %arr = alloca [3 x i8]
  store [ 3 x i8 ] c"->\00", ptr %arr
  call i32 @printf(ptr %arr)
  br label %looptop
exit:
  store [ 3 x i8] c"]\0A\00", ptr %fmt
  call i32 @printf(ptr %fmt)
  ret void
}

define void @fill_list_ordered(ptr %ll, i32 %start) {
entry:
  %fmt = alloca [ 255 x i8 ]
  %link_size = call i32 @link_size()
  %max = add i32 %start, 15
  br label %looptop
looptop:
  %idx = phi i32 [%start, %entry], [%next, %loopbody]
  %done = icmp ugt i32 %idx, %max
  br i1 %done, label %exit, label %loopbody
loopbody:
  %e = call ptr @malloc(i32 %link_size)
  %v = call ptr @malloc(i32 4)
  store i32 %idx, ptr %v
  call void @append_list(ptr %ll, ptr %e, ptr %v)
  call void @print_ll(ptr %ll)
  %next = add i32 %idx, 1
  br label %looptop
exit:
  ret void
}

define void @fill_list_alt(ptr %ll, i32 %start) {
entry:
  %fmt = alloca [ 255 x i8 ]
  %link_size = call i32 @link_size()
  %max = add i32 %start, 16
  br label %looptop
looptop:
  %idx = phi i32 [%start, %entry], [%next, %loopend]
  %done = icmp ugt i32 %idx, %max
  br i1 %done, label %exit, label %loopbody
loopbody:
  %e = call ptr @malloc(i32 %link_size)
  %v = call ptr @malloc(i32 4)
  store i32 %idx, ptr %v
  %m = urem i32 %idx, 2
  %iseven = icmp eq i32 %m, 0
  br i1 %iseven, label %even, label %odd
even:
  call void @append_list(ptr %ll, ptr %e, ptr %v)
  br label %loopend
odd:
  call void @prepend_list(ptr %ll, ptr %e, ptr %v)
  br label %loopend
loopend:
  call void @print_ll(ptr %ll)
  %next = add i32 %idx, 1
  br label %looptop
exit:
  ret void
}
define void @clear_list_alt(ptr %ll) {
entry:
  br label %looptop
looptop:
  %idx = phi i32 [0, %entry], [%next, %loopend]
  %len = call i32 @len_list(ptr %ll)
  %done = icmp eq i32 %len, 0
  br i1 %done, label %exit, label %loopbody
loopbody:
  %m = urem i32 %idx, 2
  %iseven = icmp eq i32 %m, 0
  br i1 %iseven, label %even, label %odd
even:
  %f = call ptr @pop_front(ptr %ll)
  %v = call ptr @link_value(ptr %f)
  call void @free(ptr %v)
  call void @free(ptr %f)
  br label %loopend
odd:
  %b = call ptr @pop_back(ptr %ll)
  %v2 = call ptr @link_value(ptr %b)
  call void @free(ptr %v2)
  call void @free(ptr %b)
  br label %loopend
loopend:
  call void @print_ll(ptr %ll)
  %next = add i32 %idx, 1
  br label %looptop
exit:
  ret void
}

define void @clear_from_back(ptr %ll) {
entry:
  %start = call ptr @linked_list_front(ptr %ll)
  br label %looptop
looptop:
  %head = phi ptr [%start, %entry], [%next, %loopbody]
  %done = icmp eq ptr %head, null
  br i1 %done, label %exit, label %loopbody
loopbody:
  %f = call ptr @pop_back(ptr %ll)
  %v = call ptr @link_value(ptr %f)
  call void @free(ptr %v)
  call void @free(ptr %f)
  call void @print_ll(ptr %ll)
  %next = call ptr @linked_list_front(ptr %ll)
  br label %looptop
exit:
  ret void
}

define void @clear_from_front(ptr %ll) {
entry:
  %start = call ptr @linked_list_front(ptr %ll)
  br label %looptop
looptop:
  %head = phi ptr [%start, %entry], [%next, %loopbody]
  %done = icmp eq ptr %head, null
  br i1 %done, label %exit, label %loopbody
loopbody:
  %f = call ptr @pop_front(ptr %ll)
  %v = call ptr @link_value(ptr %f)
  call void @free(ptr %v)
  call void @free(ptr %f)
  call void @print_ll(ptr %ll)
  %next = call ptr @linked_list_front(ptr %ll)
  br label %looptop
exit:
  ret void
}

define i32 @main() !dbg !1 {
entry:
  %list_size = call i32 @linked_list_size()
  %link_size = call i32 @link_size()
  %list = alloca i8, i32 %list_size
  call void @init_list(ptr %list)
  call void @fill_list_ordered(ptr %list, i32 0)
  call void @clear_from_back(ptr %list)
  call void @fill_list_ordered(ptr %list, i32 100)
  call void @clear_from_front(ptr %list)
  call void @fill_list_alt(ptr %list, i32 200)
  call void @clear_list_alt(ptr %list)
  ret i32 0
}

declare i32 @linked_list_size()
declare i32 @link_size()
declare void @init_list(ptr)
declare i1 @is_tail(ptr)
declare i32 @len(ptr)
declare void @init_link(ptr, ptr)
declare ptr @find_tail(ptr)
declare void @append(ptr, ptr, ptr)
declare void @prepend(ptr, ptr, ptr)
declare ptr @pop_front(ptr)
declare ptr @pop_back(ptr)
declare void @append_list(ptr, ptr, ptr)
declare void @prepend_list(ptr, ptr, ptr)
declare i32 @len_list(ptr)
declare i32 @printf(ptr, ...)
declare ptr @linked_list_front(ptr)
declare ptr @link_next(ptr)
declare ptr @link_value(ptr)
declare ptr @malloc(i32)
declare void @free(ptr)


!0 = !DIFile(filename: "test.ll", directory: "linked_list/")
!1 = distinct !DISubprogram(name: "main", scope: !4, file: !0, line: 163, spFlags: DISPFlagDefinition)
!4 = distinct !DICompileUnit(language: DW_LANG_C99, file: !0)
