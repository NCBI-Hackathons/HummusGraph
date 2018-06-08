#!/bin/bash

set -e
set -o pipefail

#   This script aligns a full genome assembly to a reference genome. This outputs a SAM file.

function Usage() {
    echo -e "\
Usage: ./minimap2_full_genome-asm5.sh [DEP_DIR] [REF] [ASSEMBLY_LIST] [OUT_DIR] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REF] is the full filepath to the reference.fa file
    3) [ASSEMBLY_LIST] is a list of full filepaths to assemblies we are aligning to reference. Input should be FASTA files with .fa.gz file extension.
    4) [OUT_DIR] is the full filepath to our output directory
    \n\
Dependencies: \n\
    1) minimap2
    2) parallel
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
#   1) minimap2
#   2) parallel
DEP_DIR="$1"
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
REF=$2
ASSEMBLY_LIST=$3
OUT_DIR=$4

#   Check if output directory exists, if not make one
mkdir -p ${OUT_DIR}

function alignment() {
    local ref="$1"
    local assembly_fa="$2"
    local out_dir="$3"
    #   Sample name taken from full name of FASTA file
    sample_name=$(basename "${assembly_fa}" .fa.gz)
    #   Full genome alignment using minimap2
    minimap2 -aLx asm5 "${ref}" "${assembly_fa}" > "${out_dir}"/"${sample_name}".sam
}

export -f alignment

#   Driver function that runs the program
function main() {
    local ref="$1"
    local assembly_list="$2"
    local out_dir="$3"
    parallel alignment "${ref}" {} "${out_dir}" :::: "${assembly_list}"
}

export -f main

#   Run the program
main "${REF}" "${ASSEMBLY_LIST}" "${OUT_DIR}"
