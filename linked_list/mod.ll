; A linked list's parent object
; @field head the first entry in the linked list
%LinkedList = type { ptr }
; A single link in the linked list
; @field value the value of the node
; @field next the pointer to the next value in the list, null if this is the tail 
%Link = type { ptr, ptr }

define i32 @linked_list_size() {
entry:
  %size_ptr = getelementptr [1 x %LinkedList], ptr null, i32 1
  %size = ptrtoint ptr %size_ptr to i32
  ret i32 %size
}

define i32 @link_size() {
entry:
  %size_ptr = getelementptr [1 x %Link], ptr null, i32 1
  %size = ptrtoint ptr %size_ptr to i32
  ret i32 %size
}

; Initialize a linked list with a `null` pointer as `head`
; @param %dest {%LinkedList*} the pointer to initialize
define void @init_list(ptr sret(%LinkedList) %dest) {
  %head_ptr = getelementptr %LinkedList, ptr %dest, i32 0, i32 0
  store ptr null, ptr %head_ptr
  ret void
}

; Is this link in the chain the tail of the list?
; @param %node {%Link*} the node to test
; @return true if this node is the tail
define i1 @is_tail(ptr %node) {
entry:
  %i_ptr = getelementptr %Link, ptr %node, i32 0, i32 0
  %i = load i32, ptr %i_ptr
  %next_ptr = getelementptr %Link, ptr %node, i32 0, i32 1
  %next = load ptr, ptr %next_ptr
  %ret = icmp eq ptr %next, null
  ret i1 %ret
}

; Walk the chain from this link, counting each node until the tail is reached
; @param %list {%Link*} The starting node to count from
; @return the total count from this node to the tail
define i32 @len(ptr %list) {
entry:
  br label %looptop
looptop:
  %current = phi ptr [%list, %entry], [%next, %loopcont]
  %last_ct = phi i32 [0, %entry], [%ct, %loopcont]
  br label %loopbody
loopbody:
  %ct = add i32 %last_ct, 1
  %is_done = call i1 @is_tail(ptr %current)
  br i1 %is_done, label %exit, label %loopcont
loopcont:
  %next_ptr = getelementptr %Link, %Link** %current, i32 0, i32 1
  %next = load %Link*, ptr %next_ptr
  br label %looptop
exit:
  ret i32 %ct
}

; Initialize a single link, with a `null` next and the provided value
; @param %dest {Link*} the link to initialize
; @param %v {ptr} the value of this link
define void @init_link(ptr %dest, ptr %v) {
  %fmt = alloca [255 x i8]
  %value = getelementptr %Link, ptr %dest, i32 0, i32 0
  store ptr %v, ptr %value
  %next = getelementptr %Link, ptr %dest, i32 0, i32 1
  store ptr null, ptr %next
  ret void
}

; Walk from this link and return the pointer to the tail element
; @param %list {%Link*} the like to start the search from
; @return {%Link*}
define ptr @find_tail(ptr %list) {
entry:
  %fmt = alloca [255 x i8]
  br label %looptop
looptop:
  %current = phi ptr [%list, %entry], [%next, %loopcont]
  br label %loopbody
loopbody:
  %is = call i1 @is_tail(ptr %current)
  br i1 %is, label %exit, label %loopcont
loopcont:
  %next_ptr = getelementptr %Link, ptr %current, i32 0, i32 1
  %next = load ptr, ptr %next_ptr
  br label %looptop
exit:
  ret ptr %current
}

; Add a new link to the end of a list
; @param %list {Link*} Some link in the list to be appended
; @param %entry {Link*} The link to append
; @param %v {i32} The new value
define void @append(ptr %list, ptr %entry, ptr %v) {
start:
  %fmt = alloca [255 x i8]
  %tail = call %Link* @find_tail(ptr %list)
  %dest_ptr = getelementptr %Link, ptr %tail, i32 0, i32 1
  call void @init_link(ptr %entry, ptr %v)
  store ptr %entry, ptr %dest_ptr
  ret void
}

; Prepend a link to the start of a list
; @param %list {Link*} The start of the list to prepend
; @param %entry {Link*} The entry to prepend
; @param %v {i32} The new value
define void @prepend(ptr %list, ptr %entry, ptr %v) {
start:
  call void @init_link(ptr %entry, ptr %v)
  %dest_ptr = getelementptr %Link, ptr %entry, i32 0, i32 1
  store ptr %list, ptr %dest_ptr
  ret void
}

define ptr @linked_list_front(ptr %list) {
entry:
  %head_ptr = getelementptr %LinkedList, ptr %list, i32 0, i32 0
  %ret = load ptr, ptr %head_ptr
  ret ptr %ret
}

define ptr @link_next(ptr %node) {
entry:
  %el_ptr = getelementptr %Link, ptr %node, i32 0, i32 1
  %el = load ptr, ptr %el_ptr
  ret ptr %el
}

define ptr @link_value(ptr %node) {
entry:
  %v_ptr = getelementptr %Link, ptr %node, i32 0, i32 0
  %v = load ptr, ptr %v_ptr
  ret ptr %v
}

; Remove the first element in a LinkedList
; @param %list {LinkedList*} The list to remove the element from
; @return {%Link*}
define ptr @pop_front(ptr %list) {
  %head_ptr = getelementptr %LinkedList, ptr %list, i32 0, i32 0
  %ret = load ptr, ptr %head_ptr
  %new_head_ptr = getelementptr %Link, ptr %ret, i32 0, i32 1
  %new_head = load ptr, ptr %new_head_ptr
  store ptr %new_head, ptr %head_ptr
  ret ptr %ret
}

; Remove the last element in a LinkedList
; @param %list {LinkedList*} The list to remove the element from
; @return {%Link*}
define ptr @pop_back(ptr %list) {
entry:
  %head_ptr = getelementptr %LinkedList, ptr %list, i32 0, i32 0
  %first = load ptr, ptr %head_ptr
  %first_tail = call i1 @is_tail(ptr %first)
  br i1 %first_tail, label %exit_first, label %looptop
looptop:
  %current = phi ptr [%first, %entry], [%next, %looptop]
  %next_ptr = getelementptr %Link, ptr %current, i32 0, i32 1
  %next = load ptr, ptr %next_ptr
  %tail = call i1 @is_tail(ptr %next)
  br i1 %tail, label %exit, label %looptop
exit_first:
  store ptr null, ptr %head_ptr
  ret ptr %first
exit:
  store ptr null, ptr %next_ptr
  ret ptr %next
}

; Append an element to a `LinkedList`
; @param %list {LinkedList*} the list
; @param %link {Link*} The link
; @param %v {i32} The value of the link
define void @append_list(ptr %list, ptr %link, ptr %v) {
entry:
  %head_ptr = getelementptr %LinkedList, ptr %list, i32 0, i32 0
  %head = load ptr, ptr %head_ptr
  %is_head = icmp ne ptr %head, null
  br i1 %is_head, label %headed, label %decap
decap:
  call void @init_link(ptr %link, ptr %v)
  store ptr %link, ptr %head_ptr
  ret void
headed:
  call void @append(%Link* %head, %Link* %link, ptr %v)
  ret void
}

define void @prepend_list(ptr %list, ptr %link, ptr %v) {
entry:
  %head_ptr = getelementptr %LinkedList, %LinkedList* %list, i32 0, i32 0
  %head = load ptr, ptr %head_ptr
  %is_null = icmp eq %Link** %head, null
  br i1 %is_null, label %decap, label %headed

decap:
  call void @init_link(ptr %link, ptr %v)
  store ptr %link, ptr %head
  ret void
headed:
  call void @prepend(ptr %head, ptr %link, ptr %v)
  store ptr %link, ptr %head_ptr
  ret void
}

; Prepend an element to a `LinkedList`
; @param %list {LinkedList*} the list
; @param %link {Link*} The link
; @param %v {i32} The value of the link
define i32 @len_list(%LinkedList* %list) {
entry:
  %head_ptr = getelementptr %LinkedList, %LinkedList* %list, i32 0, i32 0
  %head = load %Link*, %Link** %head_ptr
  %is_null = icmp eq ptr %head, null
  br i1 %is_null, label %decap, label %headed
decap:
  ret i32 0
headed:
  %ct = call i32 @len(ptr %head)
  ret i32 %ct
}
