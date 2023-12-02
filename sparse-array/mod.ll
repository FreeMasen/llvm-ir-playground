; ModuleID = 'sparse-array'
source_filename = "sparse-array.ll"

; A growable collection of a generic type
; @field capacity {i32} The current element count
; @field element_size {i32} The size of each element in the collection
; @field bitmap {i32} A bitmap for looking up if an entry is populated
; @field buffer {i8*|T*} A raw blob of memory for the elements
%SparseArray = type { i32, i32, i32, ptr }

declare ptr @malloc(i32)
declare void @free(ptr)
declare void @llvm.memcpy.p0.p0.i32(ptr, ptr, i32, i1)
declare void @llvm.memset.p0.i32(ptr, i8, i32, i1)
; declare i32 @printf(ptr, ...)

; initialize an array for an element size
; @param sa {%SparseArray*} The pointer to initialize
; @param el_size {i32} The size of each value in the collection
define void @sparse_array_init(ptr sret(%SparseArray) %sa, i32 %el_size, i32 %cap) {
entry:
    %fmt = alloca [255 x i8]
    store [36 x i8] c"sparse_array_init: el: %u, cap: %u\0A\00", ptr %fmt
    ; call i32 @printf(ptr %fmt, i32 %el_size, i32 %cap)
    ; calculate the size of a %SparseArray, taking into account the target's ptr width
    %size_ptr = getelementptr [1 x %SparseArray], ptr null, i32 1
    %size = ptrtoint ptr %size_ptr to i32
    ; set the provided %sa to all 0 values
    call void @llvm.memset.p0.i32(ptr %sa, i8 0, i32 %size, i1 false)
    ; get the size property pointer from the now zeroed memory
    %el_size_ptr = getelementptr inbounds %SparseArray, ptr %sa, i32 0, i32 1
    ; store the element size on the %SparseArray
    store i32 %el_size, ptr %el_size_ptr
    ; get the capacity property on %sa
    call void @sparse_array_set_capacity(ptr %sa, i32 %cap)
    %done = icmp eq i32 %cap, 0
    br i1 %done, label %exit, label %nonzero
nonzero:
    store [28 x i8] c"sparse_array_init->nonzero\0A\00", ptr %fmt
    ; calculate the raw bytes needed to store the buffer with a capacity of %cap
    %buf_size = mul i32 %el_size, %cap
    ; allocate the buffer
    %buf = call ptr @malloc(i32 %buf_size)
    ; get the buffer property on %sa
    %buf_ptr = getelementptr inbounds %SparseArray, ptr %sa, i32 0, i32 3
    ; store the new malloc'd bytes pointer on %sa
    store ptr %buf, ptr %buf_ptr
    br label %exit
exit:
    store [25 x i8] c"sparse_array_init->exit\0A\00", ptr %fmt
    ; call i32 @printf(ptr %fmt, i32 %el_size, i32 %cap)
    ret void
}

; Lookup the capacity of the array
define i32 @sparse_array_capacity(ptr %sa) {
entry:
    %len_ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 0
    %len = load i32, ptr %len_ptr
    ret i32 %len
}

; set the capacity propery of the array
define void @sparse_array_set_capacity(ptr %sa, i32 %len) {
entry:
    %len_ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 0
    store i32 %len, ptr %len_ptr
    ret void
}

; get the element size for this array
define i32 @sparse_array_el_size(ptr %sa) {
entry:
    %ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 1
    %size = load i32, ptr %ptr
    ret i32 %size
}

define i32 @sparse_array_bitmap(ptr %sa) {
entry:
    %ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 2
    %map = load i32, ptr %ptr
    ret i32 %map
}

define void @sparse_array_set_bitmap(ptr %sa, i32 %new) {
entry:
    %ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 2
    store i32 %new, ptr %ptr
    ret void
}

define i32 @sparse_array_next_vacant(ptr %sa) {
entry:
    %fmt = alloca [255 x i8]
    %map = call i32 @sparse_array_bitmap(ptr %sa)
    br label %looptop
looptop:
    %idx = phi i32 [0, %entry], [%next_idx, %loopbody]
    store [38 x i8] c"sparse_array_next_vacant->looptop %u\0A\00", ptr %fmt
    ; call i32 @printf(ptr %fmt, i32 %idx)
    %done = icmp uge i32 %idx, 32
    br i1 %done, label %full, label %loopbody
loopbody:
    %mask = shl i32 1, %idx
    %anded = and i32 %mask, %map
    store [47 x i8] c"sparse_array_next_vacant->loopbody %u, %u, %u\0A\00", ptr %fmt
    ; call i32 @printf(ptr %fmt, i32 %idx, i32 %mask, i32 %anded)
    %is_full = icmp ugt i32 %anded, 0
    %next_idx = add i32 %idx, 1
    br i1 %is_full, label %looptop, label %exit
exit:
    store [35 x i8] c"sparse_array_next_vacant->exit %u\0A\00", ptr %fmt
    ; call i32 @printf(ptr %fmt, i32 %idx)
    ret i32 %idx
full:
    ret i32 -1
}

define void @sparse_array_set_bit(ptr %sa, i32 %idx) {
entry:
    %mask = shl i32 1, %idx
    %curr = call i32 @sparse_array_bitmap(ptr %sa)
    %updated = or i32 %curr, %mask
    call void @sparse_array_set_bitmap(ptr %sa, i32 %updated)
    ret void
}

define void @sparse_array_unset_bit(ptr %sa, i32 %idx) {
entry:
    %mask = shl i32 1, %idx
    %curr = call i32 @sparse_array_bitmap(ptr %sa)
    %updated = xor i32 %curr, %mask
    call void @sparse_array_set_bitmap(ptr %sa, i32 %updated)
    ret void
}

define i1 @sparse_array_is_set(ptr %sa, i32 %idx) {
entry:
    %max_idx = call i32 @sparse_array_capacity(ptr %sa)
    %oor = icmp ugt i32 %idx, %max_idx
    br i1 %oor, label %empty, label %inrange
inrange:
    %mask = shl i32 1, %idx
    %map = call i32 @sparse_array_bitmap(ptr %sa)
    %is_full = and i32 %map, %mask
    %is_full1 = icmp ugt i32 %is_full, 0
    ret i1 %is_full1
empty:
    ret i1 0
}

; Insert an element into this array at the provided index, the element
; is provided as a ptr, probably created via `alloca` since this function 
; will perform a `memcpy` from the provided `ptr` to the arrays's backing store
;
; warning: This will blindly write the value into %idx w/o checking for vacancy
; @param sa {%SparseArray*}
; @param element {i8*|T*}
; @returns {i1} 0 if idx is out of range; 1 if idx is in range 
define i1 @sparse_array_insert(ptr %sa, ptr %element, i32 %idx) {
entry:
    %cap = call i32 @sparse_array_capacity(ptr %sa)
    %is_oor = icmp ugt i32 %idx, %cap
    br i1 %is_oor, label %oor, label %inrange
inrange:
    %el_size = call i32 @sparse_array_el_size(ptr %sa)
    %offset_idx = mul i32 %el_size, %idx
    ; lookup the slice pointer
    %buf_ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 3
    %buf = load ptr, ptr %buf_ptr
    %offset = getelementptr [0 x i8], ptr %buf, i32 0, i32 %offset_idx
    ; copy the element into the offset
    call void @llvm.memcpy.p0.p0.i32(ptr %offset, ptr %element, i32 %el_size, i1 0)
    call void @sparse_array_set_bit(ptr %sa, i32 %idx)
    ret i1 1
oor:
    ret i1 0
}

; push an element into this array, the element is provided as a ptr,
; probably created via `alloca` since this function  will perform a
; `memcpy` from the provided `ptr` to the arrays's backing store
; @param sa {%SparseArray*}
; @param element {i8*|T*}
define i1 @sparse_array_push(ptr %sa, ptr %element) {
entry:
    %next_vacant = call i32 @sparse_array_next_vacant(ptr %sa)
    %is_full = icmp slt i32 %next_vacant, 0
    br i1 %is_full, label %full, label %space
space:
    %ret = call i1 @sparse_array_insert(ptr %sa, ptr %element, i32 %next_vacant)
    ret i1 1
full:
    ret i1 0
}

; Get a pointer to the element at the index provided (0-based)
define ptr @sparse_array_get(ptr %sa, i32 %idx) {
entry:
    %is_set = call i1 @sparse_array_is_set(ptr %sa, i32 %idx)
    %max_idx = call i32 @sparse_array_capacity(ptr %sa)
    %oor = icmp ugt i32 %idx, %max_idx
    br i1 %is_set, label %full, label %empty
full:
    %el_size = call i32 @sparse_array_el_size(ptr %sa)
    %offset = mul i32 %idx, %el_size
    %buf_ptr = getelementptr %SparseArray, ptr %sa, i32 0, i32 3
    %buf = load ptr, ptr %buf_ptr
    %ret = getelementptr [0 x i8], ptr %buf, i32 0, i32 %offset
    ret ptr %ret
empty:
    ret ptr null
}

; Remove an element from the array
; 
; @param sa {%SparseArray*} The array
; @param dest {[size x i8]*} The destination to store the removed element
; @param idx {i32} the zero based index to be removed
; @return i1 0 if the idx is out of range or not populated, 
;            1 if the element was removed and placed in `dest`
define i1 @sparse_array_remove(ptr %sa, ptr %dest, i32 %idx) {
entry:
    %cap = call i32 @sparse_array_capacity(ptr %sa)
    %oor = icmp ugt i32 %idx, %cap
    br i1 %oor, label %empty, label %inrange
inrange:
    %mask = shl i32 1, %idx
    %map = call i32 @sparse_array_bitmap(ptr %sa)
    %is_full = and i32 %map, %mask
    %is_full1 = icmp ugt i32 %is_full, 0
    br i1 %is_full1, label %full, label %empty
full:
    %el_size = call i32 @sparse_array_el_size(ptr %sa)
    %el_ptr = call ptr @sparse_array_get(ptr %sa, i32 %idx)
    call void @llvm.memcpy.p0.p0.i32(ptr %dest, ptr %el_ptr, i32 %el_size, i1 0)
    call void @llvm.memset.p0.i32(ptr %el_ptr, i8 0, i32 %el_size, i1 0)
    call void @sparse_array_unset_bit(ptr %sa, i32 %idx)
    ret i1 1
empty:
    ret i1 0
}
