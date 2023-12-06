# LLVM-IR Playground

A place for me to experiment with the semantics of LLVM's IR

## Project Structure

Each directory is an experiment. The main entry point is `/<experiment>/mod.ll` along with a
`<experiment>/test.ll` file that was used to test that the module is working as expected.

## Running Tests

Each experiment should have a `run.sh` file with the command needed to run the tests. These
tests are not at all automated but instead are just reporting some of the behavior of each
experiment via `printf`.

## LLVM Version

currently written with llvm 16

## Current Working Experiments

- [fx_hash](./fx_hash/README.md): A very simple hashing algorithm
- [linked_list](./linked_list/README.md): A linked list of 32bit integers
- [rng](./rng/README.md): The Middle Square Weyl Sequence pseudo random number generator
- [sparse-array](./sparse-array/README.md): A sparse array of equally sized elements
- [vec](./vec/README.md): A contiguous, growable array of equally sized elements
