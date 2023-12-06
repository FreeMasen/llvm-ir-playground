#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MOD="$SCRIPT_DIR/mod.ll"
TEST="$SCRIPT_DIR/test.ll"

llvm-link $MOD $TEST | lli \
 && llvm-link $MOD $TEST | lli - "Hello, world!" \
 && llvm-link $MOD $TEST | lli - "Goodbye world" \
 && llvm-link $MOD $TEST | lli - "howdy folks" \
 && llvm-link $MOD $TEST | lli - "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
