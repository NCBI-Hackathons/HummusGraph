#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
\n\
This script takes a list of gzipped FASTA file (containing all individuals of interest) and a reference.fa file, aligns using Minimap2, and outputs a SAM file.
\n\
Usage: ./minimap2_full_genome-asm10_parallel.sh [DEP_DIR] [REF] [READS_LIST] [OUT_DIR] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REF] is the full filepath to the reference.fa file
    3) [READS_LIST] is a list of full filepaths to gzipped FASTA files (.fa.gz file extension) containing genome assemblies of interest. NOTE: must have .fa.gz file extension, otherwise script will break.
    4) [OUT_DIR] is the full filepath to our output directory
    \n\
Dependencies: \n\
    1) minimap2
    2) GNU parallel
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
DEP_DIR="$1"
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
REF="$2"
READS_LIST="$3"
OUT_DIR="$4"

#   Check if output directory exists, if not make one
mkdir -p "${OUT_DIR}"

function alignment() {
    local ref="$1"
    local reads="$2"
    local out_dir="$3"
    #   Sample name taken from full name of gzipped FASTA file
    sample_name=$(basename "${reads}" .fa.gz)
    #   Full genome alignment using minimap2
    #   asm10 is one of Minimap2 presets, change depending on organism population diversity
    minimap2 -aLx asm10 "${ref}" "${reads}" > "${out_dir}"/"${sample_name}"_asm10.sam
}

export -f alignment

function main() {
    local ref="$1"
    local reads_list="$2"
    local out_dir="$3"
    #   Read map our samples using Minimap2 full genome mode
    parallel alignment "${ref}" {} "${out_dir}" :::: "${reads_list}"
}

export -f main

#   Run the program
main "${REF}" "${READS_LIST}" "${OUT_DIR}"
