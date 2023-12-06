; Fx hash is a very fast non-crypo hash function developed
; at mozilla, the hash function performs 3 steps
; - rotate 5
; - xor the result of rotation and the orignal value
; - multiply the result of xor by 656542357
%FxHasher = type { i32 }

; This is used for the rotate operation, when a and b are equal
; the resut is rotation by c
declare i32 @llvm.fshl.i32(i32 %a, i32 %b, i32 %c)

define i32 @fx_hasher_size() {
    %size_ptr = getelementptr [1 x %FxHasher], ptr null, i32 1
    %size = ptrtoint ptr %size_ptr to i32
    ret i32 %size
}

; write a u32 to the hasher's state
;
; @param %hasher {FxHasher*} The hasher
; @param %v {i32} The value to write to the state
define void @fx_hasher_write_u32(ptr %hasher, i32 %v) {
entry:
    %curr_ptr = getelementptr %FxHasher, ptr %hasher, i32 0, i32 0
    %curr = load i32, ptr %curr_ptr
    %rot = call i32 @llvm.fshl.i32(i32 %curr, i32 %curr, i32 5)
    %x = xor i32 %rot, %v
    %m = mul nuw i32 %x, 656542357
    store i32 %m, ptr %curr_ptr
    ret void
}

; write a single u8 to the haher's state
;
; @param %hasher {FxHasher*} The hasher
; @param %v {i8} The value to write to the state
define void @fx_hasher_write_u8(ptr %hasher, i8 %v) {
    %wrd = zext i8 %v to i32
    call void @fx_hasher_write_u32(ptr %hasher, i32 %wrd)
    ret void
}

; write a u64 to the hasher's state, this splits the u64 in 2
; and writes them in sequence
;
; @param %hasher {FxHasher*} The hasher
; @param %v {i64} The value to write to the state
define void @fx_hasher_write_u64(ptr %hasher, i64 %v) {
    %wrd1 = trunc i64 %v to i32
    %wrd2_pre = lshr i64 %v, 32
    %wrd2 = trunc i64 %wrd2_pre to i32
    call void @fx_hasher_write_u32(ptr %hasher, i32 %wrd1)
    call void @fx_hasher_write_u32(ptr %hasher, i32 %wrd2)
    ret void
}

; get the value of this hasher's state
;
; @param %hasher {FxHasher*} The hasher
define i64 @fx_hasher_get_value(ptr %hasher) {
    %curr_ptr = getelementptr %FxHasher, ptr %hasher, i32 0, i32 0
    %curr = load i32, ptr %curr_ptr
    %ret = zext i32 %curr to i64
    ret i64 %ret
}

; Perform a single step in the process of hashing a string
;
; @param %hasher {FxHasher*} The hasher
; @param %buf {i8*} argument should be a non-null pointer to a string of i8 values
; @param %len {i32} argument should be an accurate length remaining in the string
; @return value is the number of bytes consumed
define i32 @fx_hasher_write_step(ptr %hasher, ptr %buf, i32 %len) {
entry:
    %is_four = icmp uge i32 %len, 4
    br i1 %is_four, label %at_least_four, label %only_one
only_one:
    %one = load i8, ptr %buf
    %one_ext = zext i8 %one to i32
    call void @fx_hasher_write_u32(ptr %hasher, i32 %one_ext)
    ret i32 1
at_least_four:
    %b4 = getelementptr inbounds [4 x i8], ptr %buf, i32 0, i32 0
    %i4 = load i32, ptr %b4
    call void @fx_hasher_write_u32(ptr %hasher, i32 %i4)
    ret i32 4
}

; Perform a single step in the process of hashing a string
;
; @param %hasher {FxHasher*} The hasher
; @param %buf {i8*} The string to write
; @param %len {i32} The length of the string
define void @fx_hasher_write(ptr %hasher, ptr %buf, i32 %len) {
entry:
    br label %looptop
looptop:
    %rem_len = phi i32 [%len, %entry], [%next_len, %loopbody]
    %buf_ptr = phi ptr [%buf, %entry], [%next_ptr, %loopbody]
    %done = icmp ule i32 %rem_len, 0
    br i1 %done, label %exit, label %loopbody
loopbody:
    %removed = call i32 @fx_hasher_write_step(ptr %hasher, ptr %buf_ptr, i32 %rem_len)
    %next_len = sub i32 %rem_len, %removed
    %next_ptr = getelementptr [5 x i8], ptr %buf_ptr, i32 0, i32 %removed
    br label %looptop
exit:
    call void @fx_hasher_write_u32(ptr %hasher, i32 255)
    ret void
}

; Initialize a hasher
define void @fx_hasher_init(ptr sret(%FxHasher) %hasher) {
    %v = getelementptr %FxHasher, ptr %hasher, i32 0, i32 0
    store i32 0, ptr %v
    ret void
}
