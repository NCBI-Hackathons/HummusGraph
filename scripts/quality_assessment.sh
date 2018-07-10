#!/bin/sh

set -e
set -o pipefail

#   This script runs FastQC on a series of samples and writes a summary table of the results
#   Note: script was adapted from Morrell Lab's sequence_handling pipeline (https://github.com/MorrellLAB/sequence_handling)
#   Not using sequence_handling pipeline directly because it was developed specifically
#   for MSI UMN high performance computing system (Portable Batch System)

function Usage() {
    echo -e "\
\n\
This script runs FastQC on a series of samples and writes a summary table of the results.
\n\
Usage: ./quality_assessment.sh [DEP_DIR] [SAMPLE_LIST] [OUT_DIR] [PROJECT] [SIZE] \n\
\n\
Where: \n\
    1) [DEP_DIR] is the full filepath to the directory containing dependencies (i.e. /path/to/bin)
    2) [SAMPLE_LIST] is a list of full filepaths to fastq files
    3) [OUT_DIR] is the full filepath to our output directory
    4) [PROJECT] is the name of our project. This will get used to name summary statistic files.
    5) [SIZE] is one of: a) size of genome for WGS, b) size of capture region for exome capture, or
        c) put "NA" if unavailable.
    \n\
    Example directory tree: if OUT_DIR=/path/to/file, output files will be in
    OUT_DIR/Quality_Assessment (/path/to/file/Quality_Assessment). The Quality_Assessment directory automatically
    gets created within this script.

Dependencies: \n\
    1) fastqc
    2) GNU parallel
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
SAMPLE_LIST="$2"
OUT_DIR="$3"
PROJECT="$4"
SIZE="$5"

#   A function to unzip and parse FASTQC files
#   Inspired by Paul Hoffman's RNA version of sequence_handling at https://github.com/LappalainenLab/sequence_handling/
function summarizeQC() {
    local zipFile="$1" # The name of the zip file
    local size="$2" # The estimated size of the covered region
    local out="$3" # The out directory
    local project="$4" # The name of the project
    local sampleName="$(basename ${zipFile} _fastqc.zip)" # The name of the sample
    local zipDir="$(basename ${zipFile} .zip)" # The name of the directory after unzipping
    (set -x; unzip -q "${zipFile}" -d "$(dirname ${zipDir})") # Unzip the zip file
    # Get PASS/WARN/FAIL data from the summary.txt file
    local PerBaseSequenceQuality=$(grep "Per base sequence quality" ${zipDir}/summary.txt | cut -f 1)
    local PerTileSequenceQuality=$(grep "Per tile sequence quality" ${zipDir}/summary.txt | cut -f 1)
    local PerSequenceQualityScores=$(grep "Per sequence quality scores" ${zipDir}/summary.txt | cut -f 1)
    local PerBaseSequenceContent=$(grep "Per base sequence content" ${zipDir}/summary.txt | cut -f 1)
    local PerSequenceGCContent=$(grep "Per sequence GC content" ${zipDir}/summary.txt | cut -f 1)
    local PerBaseNContent=$(grep "Per base N content" ${zipDir}/summary.txt | cut -f 1)
    local SequenceLengthDistribution=$(grep "Sequence Length Distribution" ${zipDir}/summary.txt | cut -f 1)
    local SequenceDuplicationLevels=$(grep "Sequence Duplication Levels" ${zipDir}/summary.txt | cut -f 1)
    local OverrepresentedSequences=$(grep "Overrepresented sequences" ${zipDir}/summary.txt | cut -f 1)
    local AdapterContent=$(grep "Adapter Content" ${zipDir}/summary.txt | cut -f 1)
    local KmerContent=$(grep "Kmer Content" ${zipDir}/summary.txt | cut -f 1)
    # Get sequence data from the fastqc_data.txt file
    local ReadCount=$(grep "Total Sequences" ${zipDir}/fastqc_data.txt | cut -f 2)
    local ReadLength=$(grep "Sequence length" ${zipDir}/fastqc_data.txt | cut -f 2)
    local GC=$(grep "%GC" ${zipDir}/fastqc_data.txt | cut -f 2)
    local PercentDeduplicated=$(grep "Total Deduplicated Percentage" ${zipDir}/fastqc_data.txt | cut -f 2)
    local Encoding=$(grep "Encoding" ${zipDir}/fastqc_data.txt | cut -f 2)
    # If the size is not set to "NA", calculate read depth estimates
    if [[ "${size}" -ne "NA" ]]
    then
        local LongestRead=$(echo ${ReadLength} | cut -d "-" -f 2) # Sometimes the read length is listed as "1-50", but most of the reads are actually 50
        local ReadDepth=$(( ${ReadCount} * ${LongestRead} / ${size} ))
    else
        local ReadDepth="NA"
    fi
    # Write the sequence data to the summary file
    echo -e "${sampleName}\t${Encoding}\t${ReadLength}\t${ReadCount}\t${ReadDepth}\t${GC}\t${PercentDeduplicated}\t${PerBaseSequenceQuality}\t${PerTileSequenceQuality}\t${PerSequenceQualityScores}\t${PerBaseSequenceContent}\t${PerSequenceGCContent}\t${PerBaseNContent}\t${SequenceLengthDistribution}\t${SequenceDuplicationLevels}\t${OverrepresentedSequences}\t${AdapterContent}\t${KmerContent}" >> "${out}/${project}_quality_summary_unfinished.txt"
    (set -x; rm -rf "${zipDir}") # Remove the unzipped directory
    (set -x; mv "${out}/${sampleName}_fastqc.html" "${out}/HTML_Files/") # Move the HTML file for this sample
    (set -x; mv "${out}/${sampleName}_fastqc.zip" "${out}/Zip_Files/") # Move the zip file for this sample
}

export -f summarizeQC

#   A function to run quality assessment
function Quality_Assessment() {
    local sampleList="$1" # What is our list of samples?
    local out="$2"/Quality_Assessment # Where are we storing our results?
    local project="$3" # What do we call our results?
    local size="$4" # What is the size of the covered region?
    mkdir -p "${out}/HTML_Files" "${out}/Zip_Files" # Make our output directories
    cat "${sampleList}" | parallel "fastqc --outdir ${out} {}" # Run FastQC in parallel
    # Make a list of all the zip files
    local zipList=$(find "${out}" -name "*.zip" | sort)
    # Add the header to the quality summary file
    echo -e "Sample name\tEncoding\tRead length\tNumber of reads\tRead depth\t%GC\tDeduplicated percentage\tPer base sequence quality\tPer tile sequence quality\tPer sequence quality scores\tPer base sequence content\tPer sequence GC content\tPer base N content\tSequence length distribution\tSequence duplication levels\tOverrepresented sequences\tAdapter content\tKmer content" > "${out}/${project}_quality_summary_unfinished.txt"
    # Calculate stats and add a row to the summary file for each sample
    parallel -v summarizeQC {} "${size}" "${out}" "${project}" ::: "${zipList}"
    # Add the header to a new file to contain the sorted list
    echo -e "Sample name\tEncoding\tRead length\tNumber of reads\tRead depth\t%GC\tDeduplicated percentage\tPer base sequence quality\tPer tile sequence quality\tPer sequence quality scores\tPer base sequence content\tPer sequence GC content\tPer base N content\tSequence length distribution\tSequence duplication levels\tOverrepresented sequences\tAdapter content\tKmer content" > "${out}/${project}_quality_summary.txt"
    # Sort the summary file based on sample name
    tail -n +2 "${out}/${project}_quality_summary_unfinished.txt" | sort >> "${out}/${project}_quality_summary.txt"
    # Remove the unsorted file
    rm "${out}/${project}_quality_summary_unfinished.txt"
    # # Change into the Zip_Files directory
    # cd "${out}/Zip_Files"
    # # Combine all plots into one file
    # fasterqc.pl -o "${out}/${project}_quality_plots.png"
    # # Remove the other file generated by fasterqc.pl
    # rm "${out}/Zip_Files/fasterqc.overrep.txt"
}

export -f Quality_Assessment

#   Run the program
Quality_Assessment "${SAMPLE_LIST}" "${OUT_DIR}" "${PROJECT}" "${SIZE}"
