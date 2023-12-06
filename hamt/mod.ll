; ModuleID = 'hamt'
source_filename = "hamt"

; Hash Array Mapped Trie
; @field root {%HamtNode.Value*|%HamtNode.Index*} The root node of this trie
; @field size {i32} The size of this trie
%Hamt = type {ptr, i32}

;
; A value node'
; @field key {ptr}
; @field value {ptr}
%HamtNode.Value = type {ptr, ptr}

;
; An index node
; @field node {ptr}
; @field index {i32}
%HamtNode.Index = type {ptr, i32}

;
; @field key {ptr}
; @field hash {i32}
; @field depth {i32}
; @field shift {i32}
%HamtHashState = type {ptr, i32, i32, i32}

declare ptr @malloc(i32)
declare void @free(ptr)
declare ptr @realloc(ptr, i32)
declare i32 @llvm.ctpop.i32(i32)
declare void @llvm.memcpy.p0.p0.i32(ptr, ptr, i32, i1)
declare void @llvm.memset.p0.i32(ptr, i8, i32, i1)
declare i32 @strncmp(ptr, ptr, i32)

; Convert the provided pointer into a tagged pointer
define ptr @hamt_get_tagged(ptr %node) {
entry:
    %as_int = ptrtoint ptr %node to i64
    %anded = and i64 %as_int, 18446744073709551612
    %ret = inttoptr i64 %anded to ptr
    ret ptr %ret
}

; Convert the provided pointer into an untagged pointer
define ptr @hamt_get_untagged(ptr %node) {
entry:  
    %as_int = ptrtoint ptr %node to i64
    %ored = or i64 %as_int, 3
    %ret = inttoptr i64 %ored to ptr
    ret ptr %ret
}

; heck if the node provided is a value node aka not an index node
define i1 @hamt_is_value(ptr %node) {
entry:
    %as_int = ptrtoint ptr %node to i64
    %anded = and i64 %as_int, 3
    %ret = icmp eq i64 %anded, 3
    ret i1 %ret
}

; Clear the bit in the index
define i32 @hamt_index_clear_bit(i32 %idx, i32 %n) {
entry:
    %shifted_n = shl i32 1, %n
    %not_shifted = xor i32 %shifted_n, -1
    %cleared = and i32 %idx, %not_shifted
    ret i32 %cleared
}

; Set the bit in the index
define i32 @hamt_index_set_bit(i32 %idx, i32 %n) {
entry:
    %shifted_n = shl i32 1, %n
    %set = or i32 %idx, %shifted_n
    ret i32 %set
}

; Get the index table for a node
define ptr @hamt_get_index_table(ptr %node) {
entry:
    %tbl_ptr_ptr = getelementptr inbounds %HamtNode.Index, ptr %node, i32 0, i32 0
    %tbl_ptr = load ptr, ptr %tbl_ptr_ptr
    ret ptr %tbl_ptr
}

; Get the index bitmap for the node
define ptr @hamt_get_index_index(ptr %node) {
entry:
    %idx_ptr_ptr = getelementptr inbounds %HamtNode.Index, ptr %node, i32 0, i32 1
    %idx_ptr = load ptr, ptr %idx_ptr_ptr
    ret ptr %idx_ptr
}

; Get the value from the node
define ptr @hamt_get_value_value(ptr %node) {
entry:
    %v_ptr_ptr = getelementptr inbounds %HamtNode.Value, ptr %node, i32 0, i32 1
    %v_ptr = load ptr, ptr %v_ptr_ptr
    ret ptr %v_ptr
}


define ptr @hamt_get_value_key(ptr %node) {
entry:
    %k_ptr_ptr = getelementptr inbounds %HamtNode.Value, ptr %node, i32 0, i32 0
    %k_ptr = load ptr, ptr %k_ptr_ptr
    ret ptr %k_ptr
}

define i32 @HashState_get_index(ptr %state) {
entry:
    %hash_ptr = getelementptr inbounds %HamtHashState, ptr %state, i32 0, i32 1
    %hash = load i32, ptr %hash_ptr
    %shift_ptr = getelementptr inbounds %HamtHashState, ptr %state, i32 0, i32 3
    %shift = load i32, ptr %shift_ptr
    %shifted = lshr i32 %hash, %shift
    %anded = and i32 %shifted, 31
    ret i32 %anded
}


define i32 @hamt_get_pos(i32 %idx, i32 %bitmap) {
entry:
    %shifted = shl i32 1, %idx
    %minus = sub i32 %shifted, 1
    %anded = and i32 %bitmap, %minus
    %ret = call i32 @llvm.ctpop.i32(i32 %anded)
    ret i32 %ret
}

define ptr @allocate_table(i32 %size) {
entry:
    %size_ptr = getelementptr ptr, ptr null, i32 1
    %el_size = ptrtoint ptr %size_ptr to i32
    %alloc_size = mul i32 %size, %size
    %ret = call ptr @malloc(i32 %alloc_size)
    ret ptr %ret 
}


define ptr @hamt_table_extend(ptr %hamt, ptr %anchor, i32 %rows, i32 %idx, i32 %pos) {
entry:
    %new_tbl = call ptr @allocate_table(i32 %rows)
    %oom = icmp eq ptr %new_tbl, null
    br i1 %oom, label %null, label %not_null
null:
    ret ptr null
not_null:
    %len_gt_z = icmp ugt i32 %rows, 0
    br i1 %len_gt_z, label %gtz, label %exit
gtz:
    %anch_tbl = call ptr @hamt_get_index_table(ptr %anchor)
    %new_tbl_zero = getelementptr [0 x %HamtNode.Index], ptr %new_tbl, i32 0, i32 0
    %anch_tbl_zero = getelementptr [0 x %HamtNode.Index], ptr %anch_tbl, i32 0, i32 0
    %size_ptr = getelementptr ptr, ptr null, i32 1
    %el_size = ptrtoint ptr %size_ptr to i32
    %cp1_size = mul i32 %pos, %el_size
    call void @llvm.memcpy.p0.p0.i32(ptr %new_tbl_zero, ptr %anch_tbl_zero, i32 %cp1_size, i1 0)
    %pos1 = add i32 %pos, 1
    %new_tbl_pos1 = getelementptr [0 x %HamtNode.Index], ptr %new_tbl, i32 0, i32 %pos1
    %anc_tbl_pos = getelementptr [0 x %HamtNode.Index], ptr %anch_tbl, i32 0, i32 %pos
    %cp2_mul = sub i32 %rows, %pos
    %cp2_size = mul i32 %el_size, %cp2_mul
    call void @llvm.memcpy.p0.p0.i32(ptr %new_tbl_pos1, ptr %anc_tbl_pos, i32 %cp2_size, i1 0)
    br label %exit
exit:
    %anch_tbl_ptr = getelementptr %HamtNode.Index, ptr %anchor, i32 0, i32 0
    %anch_tbl2 = load ptr, ptr %anch_tbl_ptr
    call void @free(ptr %anch_tbl2)
    store ptr %new_tbl , ptr %anch_tbl_ptr
    %old_idx = call i32 @hamt_get_index_index(ptr %anchor)
    %new_idx_pre = lshr i32 1, %idx
    %new_idx = or i32 %old_idx, %new_idx_pre
    %idx_ptr = getelementptr %HamtNode.Index, ptr %anchor, i32 0, i32 1
    store i32 %new_idx, ptr %idx_ptr
    ret ptr %anchor
}

define void @hamt_init_kv(ptr %kv, ptr %k, ptr %v) {
entry:
    %k_ptr = getelementptr inbounds %HamtNode.Value, ptr %kv, i32 0, i32 0
    store ptr %k, ptr %k_ptr
    %v_ptr = getelementptr inbounds %HamtNode.Value, ptr %kv, i32 0, i32 1
    store ptr %v, ptr %v_ptr
    ret void
}

define ptr @hamt_insert_kv(ptr %hamt, ptr %anchor, ptr %state, ptr %key, ptr %value) {
entry:
    %idx = call i32 @HashState_get_index(ptr %state)
    %last_idx_ptr = getelementptr %HamtNode.Index, ptr %anchor, i32 0, i32 1
    %last_idx = load i32, ptr %last_idx_ptr
    %next_idx_sh = shl i32 1, %idx
    %next_idx = or i32 %last_idx, %next_idx_sh
    %pos = call i32 @hamt_get_pos(i32 %next_idx)
    %n_rows = call i32 @llvm.ctpop.i32(i32 %last_idx)
    %new_anchor = call ptr @hamt_table_extend(ptr %hamt, ptr %anchor, i32 %n_rows, i32 %idx, i32 %pos)
    %is_null = icmp eq ptr %new_anchor, null
    br i1 %is_null, label %null, label %not_null
null:
    ret ptr null
not_null:
    %new_tbl = call ptr @hamt_get_index_table(ptr %new_anchor)
    %entry_pos_ptr = getelementptr [0 x %HamtNode.Value], ptr %new_tbl, i32 0, i32 %pos
    %entry_pos = load ptr, ptr %entry_pos_ptr
    call void @hamt_init_kv(ptr %new_tbl, ptr %key, ptr %value)
    ret ptr %entry_pos
}

define ptr @hamt_recursive_search(ptr %hamt, ptr %anchor, ptr %state, ptr %key) {
entry:
    ret ptr null
}

define ptr @hamt_get(ptr %hamt, ptr %key) {
entry:
    ret ptr null
}

define void @hamt_init(ptr %hamt) {
entry:
    %size_ptr = getelementptr ptr, ptr null, i32 1
    %el_size = ptrtoint ptr %size_ptr to i32
    %empty_root = call ptr @malloc(i32 %el_size)
    call void @llvm.memset.p0.i32(ptr %empty_root, i8 0, i32 %el_size, i1 0)
    %root_ptr = getelementptr inbounds %Hamt, ptr %hamt, i32 0, i32 0
    store ptr %empty_root, ptr %root_ptr
    %len_ptr = getelementptr inbounds %Hamt, ptr %hamt, i32 0, i32 1
    store i32 0, ptr %len_ptr
    ret void
}

define i32 @main() {
    %hamt = alloca %Hamt
    call void @hamt_init(ptr %hamt)
    %k1 = alloca i32
    %v1 = alloca [10 x i8]
    store i32 0, ptr %k1
    store [10 x i8] c"0123456789", ptr %v1
    call ptr @hamt_insert_kv(ptr %hamt, )
    ret i32 0
}
