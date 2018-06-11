#!/bin/bash

set -e
set -o pipefail

#   This script uses Samtools to index the reference.fa file.

function Usage() {
    echo -e "\
Usage: ./minimap2_full_genome-asm5.sh [DEP_DIR] [REF] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REF] is the full filepath to the reference.fa file

Dependencies: \n\
    1) samtools
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
DEP_DIR=$1
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
REF=$2

#   Index our reference.fa file
samtools faidx "${REF}"
