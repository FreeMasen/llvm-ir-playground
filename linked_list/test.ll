%LinkedList = type { ptr }
%Link = type { i32, ptr }

define void @print_i(i32 %v) {
  %fmt = alloca [255 x i8]
  store [4 x i8] c"%i\0A\00", ptr %fmt
  call i32 @printf(ptr %fmt, i32 %v)
  ret void
}

define i32 @main() {
entry:
  %list = alloca %LinkedList
  call void @init_list(ptr %list)
  %link = alloca %Link
  %ct = call i32 @len_list(ptr %list)
  call void @print_i(i32 %ct)
  call void @append_list(ptr %list, ptr %link, i32 0)
  %ct1 = call i32 @len_list(ptr %list)
  call void @print_i(i32 %ct1)
  %link2 = alloca %Link
  call void @append_list(ptr %list, ptr %link2, i32 1)
  %ct3 = call i32 @len_list(ptr %list)
  call void @print_i(i32 %ct3)
  %link3 = alloca %Link
  call void @prepend_list(ptr %list, ptr %link3, i32 2)
  %ct4 = call i32 @len_list(ptr %list)
  call void @print_i(i32 %ct4)
  call void @pop_front(ptr %list)
  %ct5 = call i32 @len_list(ptr %list)
  call void @print_i(i32 %ct5)
  call void @pop_back(ptr %list)
  %ct6 = call i32 @len_list(ptr %list)
  call void @print_i(i32 %ct6)
  ret i32 0
}

declare void @init_list(ptr %dest)
declare i1 @is_tail(%Link* %node)
declare i32 @len(%Link* %list)
declare void @init_link(ptr %dest, i32 %v)
declare ptr @find_tail(%Link* %list)
declare void @append(ptr %list, ptr %entry, i32 %v)
declare void @prepend(ptr %list, ptr %entry, i32 %v)
declare ptr @pop_front(ptr %list)
declare ptr @pop_back(ptr %list)
declare void @append_list(ptr %list, ptr %link, i32 %v)
declare void @prepend_list(ptr %list, ptr %link, i32 %v)
declare i32 @len_list(%LinkedList* %list)
declare i32 @printf(ptr, ...)
