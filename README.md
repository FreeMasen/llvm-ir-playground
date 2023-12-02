# LLVM-IR Playground

## Project Structure

Each directory is an experiement. The main entry point is `/<experiment>/mod.ll` along with a
`<experiment>/test.ll` file that was used to test that the module is working as expected.

## Running Tests

At present the only way to run the tests is to first link the module and test file and
then run the outout `.bc` file.

```shell
# this assumes that llvm's `bin` direction is in your path
llvm-link ./<experiment>/mod.ll ./<experiment>/test/.. -o ./<experiment>.bc | lli
```

## LLVM Version

currently written with llvm 16
