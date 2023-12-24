declare i32 @printf(ptr, ...)
@hw = global [ 14 x i8 ] c"Hello World!\0A\00"

define i32 @main() {
entry:
    br label %looptop
looptop:
    %iter = phi i32 [0, %entry], [%next, %loopbody]
    %done = icmp eq i32 %iter, 5
    br i1 %done, label %succ, label %loopbody
loopbody:
    %ret = call i32 @printf(ptr @hw)
    %success = icmp eq i32 %ret, 13
    %next = add i32 %iter, 1
    br i1 %success, label %looptop, label %fail
succ:
    ret i32 0
fail:
    ret i32 %ret
}
