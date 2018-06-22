#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
\n\
This script uses stampy to read map a concatenated.fa file to a reference.fa and outputs a SAM file.
\n\
Usage: ./stampy_align.sh [DEP_DIR] [REF] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REFERENCE] is the full filepath to the reference.fa file. NOTE: the reference prefix must match the .stidx file generated from stampy_prep_reference.sh
    3) [CONCAT_FA] is a single concatenated FASTA file (.fa file extension) containing all genome assemblies of interest. NOTE: must have .fa file extension, otherwise script will break.
    4) [DIVERGENCE] is our per site substitution rate. Example: for 3% divergence rate, put 0.03 as input argument
    5) [N_THREADS] is the number of threads available (i.e. Processor Cores Per Node). NOTE: this must match number of threads requested when queuing jobs
    6) [OUT_DIR] is the full filepath to our output directory. NOTE: output files will go into ${OUT_DIR}/stampy_mapped. The directory "stampy_mapped" is created in the script, so you only need to specify OUT_DIR
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
DEP_DIR="$1"
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
REFERENCE="$2"
CONCAT_FA="$3"
DIVERGENCE="$4"
N_THREADS="$5"
OUT_DIR="$6"

function stampy_align_se() {
    local ref_prefix="$1"
    local concat_fa="$2"
    local divergence="$3"
    local n_threads="$4"
    local out_dir="$5"
    #   Generate sample name from concatenated.fa file
    sample_name=$(basename "${concat_fa}" .fa)

    #   Read map using Stampy
    #       -g is the genome index file, PREFIX.stidx
    #       -h is the genome hash file, PREFIX.sthash
    #       --substitutionrate is the expected fraction of Poisson-distributed substitutions (default is 0.001)
    #       -f is the output file format
    #       -M reads to map
    #       -o is our output file
    stampy.py -g "${ref_prefix}" \
              -h "${ref_prefix}" \
              --substitutionrate="${divergence}" \
              -t "${n_threads}" \
              -f sam \
              -o "${out_dir}/stampy_mapped/${sample_name}_${divergence}.sam" \
              -M "${concat_fa}"\
              --inputformat=fasta
}

export -f stampy_align_se

function main() {
    local reference="$1"
    local concat_fa="$2"
    local divergence="$3"
    local n_threads="$4"
    local out_dir="$5"
    #   Generate reference directory from reference.fa file path
    ref_dir=$(dirname "${reference}")
    prefix=$(basename "${reference}" .fa)
    #   Go into directory with stampy compatible reference
    cd "${ref_dir}"

    #   Check if out directory exists, if not make it
    mkdir -p "${out_dir}"/stampy_mapped

    #   Align with Stampy
    stampy_align_se "${prefix}" "${concat_fa}" "${divergence}" "${n_threads}" "${out_dir}"
}

export -f main

#   Run the program
main "${REFERENCE}" "${CONCAT_FA}" "${DIVERGENCE}" "${N_THREADS}" "${OUT_DIR}"
