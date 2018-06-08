#!/bin/bash

set -e
set -o pipefail

#   This script takes in a list of SAM files and outputs BAM files.
#   Note: script was adapted from Morrell Lab's sequence_handling pipeline (https://github.com/MorrellLAB/sequence_handling)
#   Not using sequence_handling pipeline directly because it was developed specifically
#   for MSI UMN high performance computing system (Portable Batch System)

function Usage() {
    echo -e "\
Usage: ./sam_processing.sh [DEP_DIR] [SAM_LIST] [REFERENCE] [PROJECT] [OUT_DIR] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [SAM_LIST] is a list of full filepaths to sam files
    3) [REFERENCE] is the full filepath to the reference.fa file
    4) [PROJECT] is the name of our project. This will get used to name summary statistic files.
    5) [OUT_DIR] is the full filepath to our output directory
    \n\
    Example directory tree: if OUT_DIR=/path/to/file, output files will be in
    OUT_DIR/SAMTools (/path/to/file/SAMTools). The SAMTools directory automatically
    gets created within this script.

Dependencies: \n\
    1) samtools
    2) parallel
" >&2
    exit 1
}

export -f Usage

#   If we have no arguments
if [[ "$#" == 0 ]]; then Usage; fi # Display the usage message and exit

#   Dependencies
#   1) samtools
#   2) parallel
DEP_DIR="$1"
export PATH=${DEP_DIR}:${PATH}

#   Additional user provided arguments
SAM_LIST="$2"
REFERENCE="$3"
PROJECT="$4"
OUT_DIR="$5"

function makeOutDir() {
    local out_dir="$1"
    #   Check if out directory exists, if not make it
    #   Make subdirectories within SAMtools
    mkdir -p "${out_dir}"/SAMtools/Statistics/Raw_SAM_Stats \
             "${out_dir}"/SAMtools/Statistics/Sorted_BAM_Stats \
             "${out_dir}"/SAMtools/Statistics/Finished_BAM_Stats \
             "${out_dir}"/SAMtools/Intermediates/Sorted \
             "${out_dir}"/SAMtools/Intermediates/Fixed_Header \
             "${out_dir}"/SAMtools/Intermediates/Raw_BAM
}

export -f makeOutDir

function samProcessing() {
    local sam_file="$1"
    local reference="$2"
    local out="$3/SAM_Processing"
    local project="$4"
    #   Sample name, taken from full name of SAM file
    sampleName=$(basename "${sam_file}" .sam)
    #   Remove unnecessary information from @PG line
    #   Could use sed's in-place option, but that fails on some systems
    #   This method bypasses that
    sed 's/-R.*$//' "${sam_file}" > "${out}"/Intermediates/Fixed_Header/"${sampleName}"_fixed_header.sam
    #   Generate a sorted BAM file
    samtools view -bhT "${reference}" "${out}"/Intermediates/Fixed_Header/"${sampleName}"_fixed_header.sam > "${out}/Intermediates/Raw_BAM/${sampleName}_raw.bam"
    #   Create alignment statistics for the raw BAM file
    samtools flagstat "${out}/Intermediates/Raw_BAM/${sampleName}_raw.bam" > "${out}/Statistics/Raw_SAM_Stats/${sampleName}_raw.txt"
    #   Sort the raw BAM file
    samtools sort "${out}/Intermediates/Raw_BAM/${sampleName}_raw.bam" > "${out}/Intermediates/Sorted/${sampleName}_sorted.bam"
    #   Create alignment statistics for the sorted BAM file
    samtools stats "${out}/Intermediates/Sorted/${sampleName}_sorted.bam" > "${out}/Statistics/Sorted_BAM_Stats/${sampleName}_sorted.txt"
    #   Deduplicate the sorted BAM file
    samtools rmdup "${out}/Intermediates/Sorted/${sampleName}_sorted.bam" "${out}/${sampleName}.bam"
    #   Create alignment statistics using SAMTools
    samtools flagstat "${out}/${sampleName}.bam" > "${out}/Statistics/Finished_BAM_Stats/${sampleName}_finished.txt"

    #   Add the data from flagstat to the summary file
    local num_reads=$(head -n 1 "${out}/Statistics/Finished_BAM_Stats/${sampleName}_finished.txt" | cut -f 1 -d " ")
    local percent_mapped=$(grep "%" "${out}/Statistics/Finished_BAM_Stats/${sampleName}_finished.txt" | head -n 1 | cut -f 2 -d "(" | cut -f 1 -d " ")
    local percent_paired=$(grep "%" "${out}/Statistics/Finished_BAM_Stats/${sampleName}_finished.txt" | head -n 2 | tail -n 1 | cut -f 2 -d "(" | cut -f 1 -d " ")
    local percent_singleton=$(grep "%" "${out}/Statistics/Finished_BAM_Stats/${sampleName}_finished.txt" | tail -n 1 | cut -f 2 -d "(" | cut -f 1 -d " ")
    local num_split_chr=$(tail -n 2 "${out}/Statistics/Finished_BAM_Stats/${sampleName}_finished.txt" | head -n 1 | cut -f 1 -d " ")
    local percent_split_chr=$(echo "${num_split_chr}/${num_reads}" | bc -l)
    echo -e "${sampleName}\t${num_reads}\t${percent_mapped}\t${percent_paired}\t${percent_singleton}\t${percent_split_chr}" >> "${out}/Statistics/${project}_mapping_summary_unfinished.txt"
    #   Create an index for our BAM file
    samtools index "${out}/${sampleName}.bam"
    #   Rename the index file
    mv "${out}/${sampleName}.bam.bai" "${out}/${sampleName}.bai"
}

#   Export the function
export -f samProcessing

#   Driver function that runs program
function main() {
    local sam_list="$1" # What is our list of samples?
    local out_dir="$2"/SAM_Processing # Where are we storing our results?
    local ref_seq="$3" # What is our reference sequence?
    local project="$4" # What do we call our results?
    makeOutDir "${out_dir}" # Make our outdirectories
    #   Create the header for the mapping stats summary file
    echo -e "Sample name\tTotal reads\tPercent mapped\tPercent paired\tPercent singletons\tFraction with mate mapped to different chr" > "${out_dir}/SAMtools/Statistics/${project}_mapping_summary_unfinished.txt"
    #   Process our SAM files using SAMTools
    parallel samProcessing {} "${ref_seq}" "${out_dir}" "${project}" :::: "${sam_list}"
    #   Sort the mapping stats summary file
    echo -e "Sample name\tTotal reads\tPercent mapped\tPercent paired\tPercent singletons\tFraction with mate mapped to different chr" > "${out_dir}/SAMtools/Statistics/${project}_mapping_summary.txt"
    tail -n +2 "${out_dir}/SAMtools/Statistics/${project}_mapping_summary_unfinished.txt" | sort >> "${out_dir}/SAMtools/Statistics/${project}_mapping_summary.txt"
    rm "${out_dir}/SAMtools/Statistics/${project}_mapping_summary_unfinished.txt"
    #   Create a list of finished files
    find "${out_dir}/SAMtools" -name "*.bam" | sort > "${out_dir}"/SAMtools/"${project}"_BAM_list.txt
    #   Remove intermediate files
    rm -rf "${out_dir}/SAMtools/Intermediates"
}

#   Export the function
export -f main

#   Run the program
main "${SAM_LIST}" "${OUT_DIR}" "${REFERENCE}" "${PROJECT}"
