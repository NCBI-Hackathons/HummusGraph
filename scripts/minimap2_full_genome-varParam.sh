#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
\n\
This script takes a concatenated gzipped FASTA file (containing all individuals of interest) and a reference.fa file, aligns using Minimap2, and outputs a SAM file.
\n\
Usage: ./minimap2_full_genome-asm5.sh [DEP_DIR] [REF] [CONCAT_ASSEMBLY] [OUT_DIR] [SUFFIX]\n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [REF] is the full filepath to the reference.fa file
    3) [CONCAT_ASSEMBLY] is a single concatenated gzipped FASTA file (.fa.gz file extension) containing all genome assemblies of interest. NOTE: must have .fa.gz file extension, otherwise script will break.
    4) [OUT_DIR] is the full filepath to our output directory
    5) [SUFFIX] example: if input [CONCA_ASSEMBLY] filename is concatenated_assembly.fa.gz and suffix is _param1,
        output filename will be concatenated_assembly_param1.sam
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
SUFFIX="$5"
#   Parameters below are temporarily hardcoded for testing and working out bugs
#   Final script will take in command line arguments for parameters using flags
#   Defaults specified are current as of 2018-06-21
KMER_SIZE=19 # default is 15; asm5 preset is 19; asm10 preset is 19
MINIMIZER_WIN_SIZE=19 # default is 10; asm5 preset is 19; asm10 preset is 19
MATCH_SCORE=1 # default is 2; asm5 preset is 1; asm10 preset is 1
MISMATCH_PENALTY=8 # default is 4; asm5 preset is 19; asm10 preset is 9
GAP_OPEN_PENALTY=16,41 # default is 4,24; asm5 preset is 39,81; asm10 preset is 16,41
GAP_EXT_PENALTY=2,1 # default is 2,1; asm5 preset is 3,1; asm10 preset is 2,1
MIN_PEAK_DP_ALIGN_SCORE=200 # default is 80; asm5 preset is 200; asm10 preset is 200
Z_DROP_SCORE=200 # default is 200; asm5 preset is 200; asm10 preset is 200

#   Check if output directory exists, if not make one
mkdir -p "${OUT_DIR}"

function alignment() {
    local ref="$1"
    local concat_assembly="$2"
    local out_dir="$3"
    local suffix="$4"
    local kmer_size="$5"
    local minimizer_win_size="$6"
    local match_score="$7"
    local mismatch_penalty="$8"
    local gap_open_penalty="$9"
    local gap_ext_penalty="${10}"
    local min_peak_DP_align_score="${11}"
    local z_drop_score="${12}"
    #   Sample name taken from full name of gzipped FASTA file
    sample_name=$(basename "${concat_assembly}" .fa.gz)
    #   Full genome alignment using minimap2
    #   Modify mapping parameters
    minimap2 -aL \
             -k"${kmer_size}" \
             -w"${minimizer_win_size}" \
             -A"${match_score}" \
             -B"${mismatch_penalty}" \
             -O"${gap_open_penalty}" \
             -E"${gap_ext_penalty}" \
             -s"${min_peak_DP_align_score}" \
             -z"${z_drop_score}" \
             "${ref}" \
             "${concat_assembly}" > "${out_dir}"/"${sample_name}""${suffix}".sam
}

export -f alignment

#   Run the program
alignment "${REF}" "${CONCAT_ASSEMBLY}" "${OUT_DIR}" "${SUFFIX}" \
          "${KMER_SIZE}" \
          "${MINIMIZER_WIN_SIZE}" \
          "${MATCH_SCORE}" \
          "${MISMATCH_PENALTY}" \
          "${GAP_OPEN_PENALTY}" \
          "${GAP_EXT_PENALTY}" \
          "${MIN_PEAK_DP_ALIGN_SCORE}" \
          "${Z_DROP_SCORE}"
