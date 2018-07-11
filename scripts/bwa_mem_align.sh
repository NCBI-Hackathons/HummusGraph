#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
Usage: ./bwa_mem_align.sh [DEP_DIR] [REFERENCE] [SAMPLE_LIST] [OUT_DIR] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REFERENCE] is the full filepath to the reference.fa file
    3) [SAMPLE_LIST] is a list of full filepaths to gzipped fastq files
    4) [OUT_DIR] is the full filepath to our output directory
    \n\

Dependencies: \n\
    1) bwa
    2) parallel
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
#   1) bwa
#   2) parallel
DEP_DIR="$1"
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
REFERENCE="$2"
SAMPLE_LIST="$3"
OUT_DIR="$4"

function alignment() {
    local reference="$1"
    local reads="$2"
    local out_dir="$3"
    #   Sample name taken from full name of FASTA file
    sample_name=$(basename "${reads}" .fa.gz)
    #   Align using BWA MEM
    bwa mem -t 8 "${reference}" "${reads}" > "${out_dir}"/"${sample_name}".sam
}

export -f alignment

#   Driver function that runs the program
function main() {
    local reference="$1"
    local sample_list="$2"
    local out_dir="$3"
    parallel alignment "${reference}" {} "${out_dir}" :::: "${sample_list}"
}

export -f main

#   Run the program
main "${REFERENCE}" "${SAMPLE_LIST}" "${OUT_DIR}"
