; ModuleID = 'vec'
source_filename = "vec.ll"

; The backing store for the vector
; @field capacity {i32} The count of elements that can be stored
; @field buffer {i8*|T*} A raw blob of memory for the elements
%Slice = type { i32, ptr }
; A growable collection of a generic type
; @field length {i32} The current element count
; @field element_size {i32} The size of each element in the collection
; @field slice {%Slice} The backing store
%Vec = type { i32, i32, %Slice }

declare ptr @malloc(i32)
declare void @free(ptr)
declare void @llvm.memcpy.p0.p0.i32(ptr, ptr, i32, i1)
declare void @llvm.memset.p0.i32(ptr, i8, i32, i1)

; initialize a vector for an element size
; @param vec {%Vec*} The pointer to initialize
; @param el_size {i32} The size of each value in the collection
define void @vec_init(ptr %vec, i32 %el_size) {
entry:
    %size_ptr = getelementptr [1 x %Vec], ptr null, i32 1
    %size = ptrtoint ptr %size_ptr to i32
    call void @llvm.memset.p0.i32(ptr align 8 %vec, i8 0, i32 %size, i1 false)
    %el_size_ptr = getelementptr inbounds %Vec, ptr %vec, i32 0, i32 1
    store i32 %el_size, ptr %el_size_ptr
    ret void
}

; Lookup the length of the vec
define i32 @vec_len(ptr %vec) {
entry:
    %len_ptr = getelementptr %Vec, ptr %vec, i32 0, i32 0
    %len = load i32, ptr %len_ptr
    ret i32 %len
}

; set the length propery of the vec
define void @vec_set_len(ptr %vec, i32 %len) {
entry:
    %len_ptr = getelementptr %Vec, ptr %vec, i32 0, i32 0
    store i32 %len, ptr %len_ptr
    ret void
}

; set the capacity of the Slice in this vec
define void @vec_set_capacity(ptr %vec, i32 %len) {
entry:
    %len_ptr = getelementptr %Vec, ptr %vec, i32 0, i32 2, i32 0
    store i32 %len, ptr %len_ptr
    ret void
}

; get the element size for this vec
define i32 @vec_el_size(ptr %vec) {
entry:
    %ptr = getelementptr %Vec, ptr %vec, i32 0, i32 1
    %size = load i32, ptr %ptr
    ret i32 %size
}

; get the slice capacity from the vector
define i32 @vec_capacity(ptr %vec) {
entry:
    %ptr = getelementptr %Vec, ptr %vec, i32 0, i32 2, i32 0
    %size = load i32, ptr %ptr
    ret i32 %size
}

; Increase the capacity of this vector, this should be called only
; when more room is needed.
; 
; If the collection is empty, it will be initialized to 1 element size
; if the collection is not empty it will double the capacity
define void @vec_bump_capacity(ptr %vec) {
entry:
    %buf_ptr = getelementptr inbounds %Vec, ptr %vec, i32 0, i32 2, i32 1
    %cap = call i32 @vec_capacity(ptr %vec)
    %el_size = call i32 @vec_el_size(ptr %vec)
    %empty = icmp eq i32 %cap, 0
    br i1 %empty, label %alloc, label %realloc
alloc:
    %first_buf = call ptr @malloc(i32 %el_size)
    call void @vec_set_capacity(ptr %vec, i32 1)
    store ptr %first_buf, ptr %buf_ptr
    ret void
realloc:
    %new_cap = mul i32 2, %cap
    %raw_size = mul i32 %new_cap, %el_size
    %new_buf = call ptr @malloc(i32 %raw_size)
    %old_buf = load ptr, ptr %buf_ptr
    %old_size = mul i32 %cap, %el_size
    call void @llvm.memcpy.p0.p0.i32(ptr %new_buf, ptr %old_buf, i32 %old_size, i1 0)
    store ptr %new_buf, ptr %buf_ptr
    call void @free(ptr %old_buf)
    call void @vec_set_capacity(ptr %vec, i32 %new_cap)
    ret void
}

; push and element into this vector, the element is provided as a ptr,
; probably created via `alloca` since this function  will perform a
; `memcpy` from the provided `ptr` to the vector's backing store
; @param vec {%Vec*}
; @param vec {i8*|T*}
define void @vec_push(ptr %vec, ptr %element) {
entry:
    %len = call i32 @vec_len(ptr %vec)
    %el_size = call i32 @vec_el_size(ptr %vec)
    %cap = call i32 @vec_capacity(ptr %vec)
    %needs_more = icmp uge i32 %len, %cap
    br i1 %needs_more, label %realloc, label %push
realloc:
    call void @vec_bump_capacity(ptr %vec)
    br label %push
push:
    ; calculate the raw offset for the new value
    %offset_idx = mul i32 %el_size, %len
    ; calculate the next vec length
    %next_len = add i32 %len, 1
    ; lookup the slice pointer
    %buf_ptr = getelementptr %Vec, ptr %vec, i32 0, i32 2, i32 1
    %buf = load ptr, ptr %buf_ptr
    %offset = getelementptr [0 x i8], ptr %buf, i32 0, i32 %offset_idx
    ; copy the element into the offset
    call void @llvm.memcpy.p0.p0.i32(ptr %offset, ptr %element, i32 %el_size, i1 0)
    ; update the vec's length property
    call void @vec_set_len(ptr %vec, i32 %next_len)
    ret void
}

; Get a pointer to the element at the index provided (0-based)
define ptr @vec_get(ptr %vec, i32 %idx) {
entry:
    %len = call i32 @vec_len(ptr %vec)
    %out_of_range = icmp uge i32 %idx, %len
    br i1 %out_of_range, label %oor, label %cont
oor:
    ret ptr null
cont:
    %el_size = call i32 @vec_el_size(ptr %vec)
    %offset = mul i32 %idx, %el_size
    %buf_ptr = getelementptr %Vec, ptr %vec, i32 0, i32 2, i32 1
    %buf = load ptr, ptr %buf_ptr
    %ret = getelementptr [0 x i8], ptr %buf, i32 0, i32 %offset
    ret ptr %ret
}
