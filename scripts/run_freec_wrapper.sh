#!/bin/zsh

# Default values
ploidy=2
threads=1
window_size=250
step_size=250
min_mappability=0.85
excluded_chr_list=""
min_expected_gc=0.4
max_expected_gc=0.6
mates_orientation=0

# Function to display usage
#usage() {
#    echo "Usage: $0 -r <refseq> -b <bam> -p <prefix> -t <threads> -d <dir> -s <samtools> -b <bedtools> -f <freec>"
#    exit 1
#}
#
# Parse command-line arguments
while getopts "r:b:p:t:bed:f:" opt; do
    case "$opt" in
        r) refseq_tag="$OPTARG" ;;
        bam) bam="$OPTARG" ;;
        prefix) prefix="$OPTARG" ;;
        threads) threads="$OPTARG" ;;
        refseq_genome_preprocessing_dir) refseq_genome_preprocessing_dir="$OPTARG" ;;
        exclued_chr_list) excluded_chr_list="$OPTARG" ;;
        samtools) samtools="$OPTARG" ;;
        bedtools) bedtools="$OPTARG" ;;
        window) window_size="$OPTARG" ;;
        step) step_size="$OPTARG" ;;
        min_mappability) min_mappability="$OPTARG" ;;
        min_expected_gc) min_expected_gc="$OPTARG" ;;
        mates_orientation) mates_orientation="$OPTARG" ;;
        ploidy) ploidy="$OPTARG"
        freec) freec="$OPTARG" ;;
        read_length_for_mappability) read_length_for_mappability="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check required parameters
if [ -z "$refseq_tag" ] || [ -z "$bam" ] || [ -z "$prefix" ] || [ -z "$freec" ]; then
    usage
fi

echo "min_expected_gc=$min_expected_gc, max_expected_gc=$max_expected_gc"
echo "excluded_chr_list = $excluded_chr_list"

# Filter bam
excluded_chr_regex=""
if [ -n "$excluded_chr_list" ]; then
    while read -r chr; do
        excluded_chr_regex+="/$chr/d;"
    done < "$excluded_chr_list"
fi

# Use awk to filter the BAM file
samtools view -h "$bam" | awk "$excluded_chr_regex" | samtools view -b -h - > for_CNV.bam

# Reheader BAM file for FREEC
samtools view -H for_CNV.bam > FREEC.bam.header.old.sam
python3 reformat_bam_header.py FREEC.bam.header.old.sam "$refseq_genome_preprocessing_dir/$refseq_tag.FREEC_chr.dict" FREEC.bam.header.new.sam
samtools reheader FREEC.bam.header.new.sam for_CNV.bam > FREEC.bam

# Generate config file for FREEC
python3 generate_freec_config.py "$refseq_tag" "$refseq_genome_preprocessing_dir" "$ploidy" "$threads" "$min_mappability" "$min_expected_gc" "$max_expected_gc" "$window_size" "$step_size" "$mates_orientation" "FREEC.config.txt"

# Run FREEC
"$freec" -conf FREEC.config.txt

# Process output
python3 process_freec_output.py "$prefix"


