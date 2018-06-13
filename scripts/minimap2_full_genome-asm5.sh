#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
This script takes a concatenated gzipped FASTA file (containing all individuals of interest) and a reference.fa file, aligns using Minimap2, and outputs a SAM file.
\n\
Usage: ./minimap2_full_genome-asm5.sh [DEP_DIR] [REF] [CONCAT_ASSEMBLY] [OUT_DIR] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REF] is the full filepath to the reference.fa file
    3) [CONCAT_ASSEMBLY] is a single concatenated gzipped FASTA file (.fa.gz file extension) containing all genome assemblies of interest. NOTE: must have .fa.gz file extension, otherwise script will break.
    4) [OUT_DIR] is the full filepath to our output directory
    \n\
Dependencies: \n\
    1) minimap2
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
#   1) minimap2
DEP_DIR="$1"
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
REF="$2"
CONCAT_ASSEMBLY="$3"
OUT_DIR="$4"

#   Check if output directory exists, if not make one
mkdir -p "${OUT_DIR}"

function alignment() {
    local ref="$1"
    local concat_assembly="$2"
    local out_dir="$3"
    #   Sample name taken from full name of gzipped FASTA file
    sample_name=$(basename "${concat_assembly}" .fa.gz)
    #   Full genome alignment using minimap2
    #   asm5 is one of Minimap2 presets, change depending on organism population diversity
    minimap2 -aLx asm5 "${ref}" "${concat_assembly}" > "${out_dir}"/"${sample_name}".sam
}

export -f alignment

#   Run the program
alignment "${REF}" "${CONCAT_ASSEMBLY}" "${OUT_DIR}"
