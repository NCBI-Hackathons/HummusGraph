#!/bin/bash

set -e
set -o pipefail

#   This script uses Samtools to index the reference.fa file.

function Usage() {
    echo -e "\
Usage: ./minimap2_full_genome-asm5.sh [Samtools] [REF] \n\
\n\
Where: \n\
    1) [Samtools] is the full filepath to the executable script/program
    2) [REF] is the full filepath to the reference.fa file
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
SAMTOOLS=$1
#export PATH=${SAMTOOLS}:${PATH}

#   Additional user provided arguments
REF=$2

#   Index our reference.fa file
${SAMTOOLS} faidx "${REF}"
