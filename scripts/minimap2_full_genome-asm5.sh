#!/bin/bash

set -e
set -o pipefail

#   This script aligns a full genome assembly to a reference genome. This outputs a SAM file.

function Usage() {
    echo -e "\
Usage: ./minimap2_full_genome-asm5.sh [MINIMAP2] [REF] [ASSEMBLY_FA] [OUT_DIR] [OUT_PREFIX] \n\
\n\
Where: \n\
    1) [MINIMAP2] is the full filepath to the executable script
    2) [REF] is the full filepath to the reference.fa file
    3) [ASSEMBLY_FA] is the full filepath to assembly we are aligning to reference
    4) [OUT_DIR] is the full filepath to our output directory
    5) [OUT_PREFIX] is our output filename prefix
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
#   Note: this path needs to be changed
MINIMAP2=$1
export PATH=${MINIMAP2}:${PATH}

#   User provided arguments
REF=$2
ASSEMBLY_FA=$3
OUT_DIR=$4
OUT_PREFIX=$5

#   Align using minimap2
minimap2 -aLx asm5 "${REF}" "${ASSEMBLY_FA}" > "${OUT_DIR}"/"${OUT_PREFIX}".sam
