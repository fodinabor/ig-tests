#!/usr/bin/env bash

set -e
set -x

LLVM_INSTALL_DIR=/usr/WS1/ivanov2/opt/input-gen-release/
LLVM_SRC_DIR=/usr/WS1/ivanov2/src/input-gen/
INPUT_GEN_RUNTIME="${INPUT_GEN_RUNTIME:=$(readlink -f "$LLVM_SRC_DIR/input-gen-runtimes/rt-input-gen.cpp")}"
INPUT_RUN_RUNTIME="${INPUT_RUN_RUNTIME:=$(readlink -f "$LLVM_SRC_DIR/input-gen-runtimes/rt-run.cpp")}"

FUNC_NAME=kernel_gemm

. enable.sh $LLVM_INSTALL_DIR

clang -O3 -c -emit-llvm gemm.c -o gemm.bc -I../../../utilities/

# llvm-extract -S gemm.bc --func="$FUNC_NAME"

OUTDIR=./input-gen-out/
mkdir -p "$OUTDIR"
input-gen gemm.bc --output-dir "$OUTDIR" --input-run-runtime "$INPUT_RUN_RUNTIME" --input-gen-runtime "$INPUT_GEN_RUNTIME" --compile-input-gen-executables --verify --function="$FUNC_NAME"

INPUTS_DIR="./$OUTDIR/inputs/"
mkdir -p "$INPUTS_DIR"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 0 1
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.0.bin"

echo Input binary size "$(wc -c < "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.0.bin")"
