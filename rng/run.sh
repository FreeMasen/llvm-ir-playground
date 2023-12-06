#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MOD="$SCRIPT_DIR/mod.ll"
TEST="$SCRIPT_DIR/test.ll"

llvm-link $MOD $TEST | lli 
