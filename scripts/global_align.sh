#!/bin/bash

set -e
set -o pipefail

function Usage() {
    echo -e "\
This script carries out Step 1: Globally Align All Reads from https://github.com/NCBI-Hackathons/Graph_Genomes_CSHL workflow.

Usage: ./global_align.sh [SCRIPTS_DIR] [CONCAT_BAM] [REFERENCE] [CONCAT_FA] [OUT_DIR] \n\
\n\
Where: \n\
    1) [SCRIPTS_DIR] is the full filepath to Graph_Genomes_CSHL/scripts directory
    2) [CONCAT_BAM] is the full filepath to concatenated BAM file
    3) [REFERENCE] is the full filepath to the reference.fa file
    4) [CONCAT_FA] is the full filepath to the concatenated FASTA file (same one used to generate the BAM file)
    5) [OUT_DIR] is the full filepath to our output directory
\n\
Dependencies: \n\
    1) perl (this should already be installed on most HPC clusters)
    2) cloned repo of Graph_Genomes_CSHL

    If not cloned, run:
    git clone https://github.com/NCBI-Hackathons/Graph_Genomes_CSHL.git
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
SCRIPTS_DIR=$1
export PATH=${SCRIPTS_DIR}:${PATH}

#   Additional user provided arguments
CONCAT_BAM=$2
REFERENCE=$3
CONCAT_FA=$4
OUT_DIR=$5

function makeOutDir() {
    local out_dir=$1
    #   Check if out directory and sub directories exist, if not make them
    mkdir -p "${out_dir}"/step1_global_align/intermediates
}

export -f makeOutDir

function prepGlobalAlignment() {
    local concat_bam=$1
    local reference=$2
    local concat_fa=$3
    local out_dir=$4
    sample_name=$(basename "${concat_bam}" .bam)
    #   This perl script adds .sortedWithHeader file extension to output file
    BAM2AARTI.pl --BAM "${concat_bam}" \
                 --referenceFasta "${reference}" \
                 --readsFasta "${concat_fa}" \
                 --outputFile "${out_dir}"/step1_global_align/intermediates/"${sample_name}"
}

export -f prepGlobalAlignment

function findGlobalAlignments() {
    local sortedWithHeader_file=$1
    local reference=$2
    local out_dir=$3
    sample_name=$(basename "${sortedWithHeader_file}" .sortedWithHeader)
    #   This perl script outputs SAM and BAM files
    FIND_GLOBAL_ALIGNMENTS_2.pl --alignmentsFile "${sortedWithHeader_file}" \
                                --referenceFasta "${reference}" \
                                --outputFile "${out_dir}"/step1_global_align/"${sample_name}".bam
                                --outputTruncatedReads "${out_dir}"/step1_global_align/"${sample_name}"_truncatedReads.txt
                                --outputReadLengths "${out_dir}"/step1_global_align/"${sample_name}"_readLengths.txt
}

export -f findGlobalAlignments

#   Driver function
function main() {
    local concat_bam=$1
    local reference=$2
    local concat_fa=$3
    local out_dir=$4
    #   Check if out directories exist, if not make them
    makeOutDir "${out_dir}"
    #   Prepare global alignment
    prepGlobalAlignment "${concat_bam}" "${reference}" "${concat_fa}" "${out_dir}"
    #   Find global alignment
    findGlobalAlignments "${out_dir}"/step1_global_align/intermediates/"${sample_name}".sortedWithHeader "${reference}" "${out_dir}"
}

export -f main

#   Run the program
main "${CONCAT_BAM}" "${REFERENCE}" "${CONCAT_FA}" "${OUT_DIR}"
