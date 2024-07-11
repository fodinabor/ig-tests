#!/usr/bin/env bash

set -e
set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT_FILE="$SCRIPT_DIR/results.$(date -Iseconds).out"

LLVM_INSTALL_DIR=/usr/WS1/meyer61/opt/input-gen-main-quartz/
LLVM_SRC_DIR=/usr/WS1/meyer61/inputgen-llvm-main/
INPUT_GEN_RUNTIME="${INPUT_GEN_RUNTIME:=rt-input-gen.cpp}"
INPUT_RUN_RUNTIME="${INPUT_RUN_RUNTIME:=rt-run.cpp}"

FUNC_NAME=kernel_gemm

. enable.sh $LLVM_INSTALL_DIR

clang -O3 -c -emit-llvm gemm.c -o gemm.bc -I../../../utilities/
clang -O3 -c -emit-llvm "$INPUT_GEN_RUNTIME" -o rt-input-gen.bc -I../../../utilities/ -I${LLVM_SRC_DIR}/llvm/include
clang -O3 -c -emit-llvm "$INPUT_RUN_RUNTIME" -o rt-run.bc -I../../../utilities/ -I${LLVM_SRC_DIR}/llvm/include

# llvm-extract -S gemm.bc --func="$FUNC_NAME"

OUTDIR=./input-gen-out/
mkdir -p "$OUTDIR"

input-gen gemm.bc --output-dir "$OUTDIR" --input-run-runtime "$INPUT_RUN_RUNTIME" --input-gen-runtime "$INPUT_GEN_RUNTIME" --compile-input-gen-executables --verify --function="$FUNC_NAME" --compile-input-gen-executables=false
llvm-link input-gen-out/input-gen.function.kernel_gemm.generate.bc rt-input-gen.bc -o input-gen-out/merged.bc
clang++ "-ldl" "-rdynamic" input-gen-out/merged.bc "-o" "./input-gen-out//input-gen.function.kernel_gemm.generate.a.out" "-O3" "-DNDEBUG"  -march=native

llvm-link input-gen-out/input-gen.function.kernel_gemm.run.bc rt-run.bc -o input-gen-out/merged_run.bc
clang++ "-ldl" "-rdynamic" input-gen-out/merged_run.bc "-o" "./input-gen-out//input-gen.function.kernel_gemm.run.a.out" "-O3" "-DNDEBUG"  -march=native


INPUTS_DIR="./$OUTDIR/inputs/"
mkdir -p "$INPUTS_DIR"
echo -n > "$OUTPUT_FILE"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 0 1 >> "$OUTPUT_FILE"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 2 3 >> "$OUTPUT_FILE"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 5 6 >> "$OUTPUT_FILE"
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.0.bin" >> "$OUTPUT_FILE"
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.2.bin" >> "$OUTPUT_FILE"
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.5.bin" >> "$OUTPUT_FILE"

echo Input binary size "$(wc -c < "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.0.bin")" >> "$OUTPUT_FILE"

clang -O3 gemm.c -o gemm.org -I../../../utilities/ ../../../utilities/polybench.c -DMAIN -DPOLYBENCH_TIME  -march=native
echo "polybench time: " >> "$OUTPUT_FILE"
./gemm.org  >> "$OUTPUT_FILE"
echo "s" >> "$OUTPUT_FILE"


echo "------- O1 -----" >> "$OUTPUT_FILE"

clang -O1 -c -emit-llvm gemm.c -o gemm.bc -I../../../utilities/
clang -O1 -c -emit-llvm "$INPUT_GEN_RUNTIME" -o rt-input-gen.bc -I../../../utilities/ -I${LLVM_SRC_DIR}/llvm/include
clang -O1 -c -emit-llvm "$INPUT_RUN_RUNTIME" -o rt-run.bc -I../../../utilities/ -I${LLVM_SRC_DIR}/llvm/include

input-gen gemm.bc --output-dir "$OUTDIR" --input-run-runtime "$INPUT_RUN_RUNTIME" --input-gen-runtime "$INPUT_GEN_RUNTIME" --compile-input-gen-executables --verify --function="$FUNC_NAME" --compile-input-gen-executables=false
llvm-link input-gen-out/input-gen.function.kernel_gemm.generate.bc rt-input-gen.bc -o input-gen-out/merged.bc
clang++ "-ldl" "-rdynamic" input-gen-out/merged.bc "-o" "./input-gen-out//input-gen.function.kernel_gemm.generate.a.out" "-O1" "-DNDEBUG"  -march=native

llvm-link input-gen-out/input-gen.function.kernel_gemm.run.bc rt-run.bc -o input-gen-out/merged_run.bc
clang++ "-ldl" "-rdynamic" input-gen-out/merged_run.bc "-o" "./input-gen-out//input-gen.function.kernel_gemm.run.a.out" "-O1" "-DNDEBUG"  -march=native


INPUTS_DIR="./$OUTDIR/inputs/"
mkdir -p "$INPUTS_DIR"
echo -n >> "$OUTPUT_FILE"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 0 1 >> "$OUTPUT_FILE"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 2 3 >> "$OUTPUT_FILE"
INPUT_GEN_DISABLE_BRANCH_HINTS=1 TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.generate.a.out" "$INPUTS_DIR" 5 6 >> "$OUTPUT_FILE"
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.0.bin" >> "$OUTPUT_FILE"
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.2.bin" >> "$OUTPUT_FILE"
TIMING=1 "$OUTDIR/input-gen.function.kernel_gemm.run.a.out" "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.5.bin" >> "$OUTPUT_FILE"

echo Input binary size "$(wc -c < "$INPUTS_DIR/input-gen.function.kernel_gemm.generate.a.out.input.0.bin")" >> "$OUTPUT_FILE"

clang -O1 gemm.c -o gemm.org -I../../../utilities/ ../../../utilities/polybench.c -DMAIN -DPOLYBENCH_TIME -march=native
echo "polybench time: " >> "$OUTPUT_FILE"
./gemm.org  >> "$OUTPUT_FILE"
echo "s" >> "$OUTPUT_FILE"

