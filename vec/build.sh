#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MOD="$SCRIPT_DIR/mod.ll"
TEST="$SCRIPT_DIR/test.ll"
NAME="$(basename $SCRIPT_DIR)"
TEMP="$(mktemp)"
OUT="$(echo $NAME)_test"
llvm-link $MOD $TEST \
    | llc --filetype=obj -o $TEMP - \
    && clang "$TEMP" -o $OUT
