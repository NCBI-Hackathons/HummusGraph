#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
\n\
This script prepares the reference.fa file for alignment with Stampy. It builds a genome file and builds a hash table.
\n\
Usage: ./stampy_prep_reference.sh [DEP_DIR] [REF] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REFERENCE] is the full filepath to the reference.fa file
    \n\
Dependencies: \n\
    1) stampy
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
REFERENCE="$2"

function buildGenome() {
    local reference="$1"
    local ref_prefix="$2"
    stampy.py -G "${ref_prefix}" "${reference}"
}

export -f buildGenome

function buildHashTable() {
    local ref_prefix="$1"
    stampy.py -g "${ref_prefix}" -H "${ref_prefix}"
}

export -f buildHashTable

#   Driver function
function main() {
    local reference="$1"
    directory=$(dirname "${reference}")
    prefix=$(basename "${reference}" .fa)
    #   Go into directory containing reference
    cd "${directory}"
    #   Build genome index, outputs prefix.stidx from fasta file
    buildGenome "${reference}" "${prefix}"
    #   Build hast table, outputs prefix.sthash file
    buildHashTable "${prefix}"
}

export -f main

#   Run the program
main "${REFERENCE}"
