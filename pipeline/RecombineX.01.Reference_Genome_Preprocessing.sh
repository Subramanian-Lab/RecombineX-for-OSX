#!/bin/zsh
set -e -o pipefail

# Loading environment variables
source ./../../env.sh
source "$BUILD_DIR/conda/etc/profile.d/conda.sh"
source "$BUILD_DIR/conda/etc/profile.d/mamba.sh"

mamba activate recombinex_venv

############## Set Project-Specific Variables #############
reference_genome_assembly="./../00.Reference_Genome/SGDref.genome.fa.gz" # The input reference genome assembly in FASTA format with or without gz compression (eg. *.fa, *.fasta, *.fa.gz, *.fasta.gz). Default = "./../00.Reference_Genome/SGDref.genome.fa.gz".
use_centromere_annotation="yes" # Whether to use the centromere annotation inormation. When set to "yes" (default), you need to also provide the path to the centromere GFF file in the "centromere_gff=" option below. Set this option to "no" when running RecombineX for the mitochondrial genome. Default = "yes".
centromere_gff="./../00.Reference_Genome/SGDref.centromere.gff" # Path to the centromere annotation GFF3 file. Required when "use_centromere_annotation" = "yes". Otherwise, leave it empty. Set this option to "" when running RecombineX for the mitochrondrial genome. Default = "./../00.Reference_Genome/SGDref.centromere.gff".

window_size=250 # The window size fo the non-overlapping sliding-window-based CNV profiling. Default = 250 (i.e. 250 bp)
threads=4 # The number of threads to use. Default = "4"
debug="no" # Whether to keep intermediate files for debugging. Use "yes" if prefer to keep intermediate files, otherwise use "no". Default = "no"

##########################################################

# Process the pipeline

# Parameters for CNV profiling
lower_quantile=15
upper_quantile=85
min_mappability=0.85 # The minimal mappability for sliding-window-based CNV profiling. Deafult = "0.85".

raw_read_length=100 # RecombineX will fix this value for simplicity. There is no need to adjust it for the actual lengths of your Illumina reads.
check_duplicates_by_windowmasker="no" # Whether to mark duplicated regions using windowmasker. Default = "no".
ram_for_windowmaker="1536" # Accessible RAM (in MB) for windowmasker. Default = 1536.

excluded_chr_list_for_cnv_profiling="" # The relative path to the list for specifiying chromosomes/scaffolds/contigs to be excluded for CNV profiling. Default = "".

# Function to test the file existence
test_file_existence () {
    filename=$1
    if [[ ! -f $filename ]]
    then
        echo "the file $filename does not exists! process terminated."
        exit
    fi
}

# Checking the existence of genome assembly and centromere_gff file
echo ""
echo "Check the existence of genome_assembly"
test_file_existence $reference_genome_assembly

if [[ $use_centromere_annotation == "yes" ]]
then
    if [[ -z $centromere_gff ]]
    then
        echo ""
        echo "Error: No centromere gff file provided."
    else 
        echo ""
        echo "Check the existence of centromere gff"
        test_file_existence $centromere_gff
    fi
fi

echo "Convert all the bases in the input genome assembly into uppercases first..."
python $RECOMBINEX_HOME/scripts/switch_letter_cases_in_fasta.py --input_fasta $reference_genome_assembly --output_fasta ref.genome.raw.fa --case upper

# Relabel the genome assembly file
echo ""
echo "Relabel sequences in the genome assembly with the genome_tag prefix .."
cat ref.genome.raw.fa | sed "s/>/>ref_/g" > ref.genome.raw.relabel.fa

# Creating index for the modified genome file
$SAMTOOLS_DIR/samtools faidx ref.genome.raw.relabel.fa

# Checking duplicate sequences using WindowMasker
if [[ $check_duplicates_by_windowmasker == "yes" ]]
then
    $WINDOWMASKER_DIR/windowmasker -checkdup true -mk_counts -in ref.genome.raw.relabel.fa -out ref.genome.raw.relabel.masking_library.ustat -mem $ram_for_windowmaker
else
    $WINDOWMASKER_DIR/windowmasker -mk_counts -in ref.genome.raw.relabel.fa -out ref.genome.raw.relabel.masking_library.ustat -mem $ram_for_windowmaker

fi

# Softmasking low-complexity regions in the genome
$WINDOWMASKER_DIR/windowmasker -ustat ref.genome.raw.relabel.masking_library.ustat -dust true -in ref.genome.raw.relabel.fa -out ref.genome.softmask.relabel.fa -outfmt fasta

# Hardmasking
python $RECOMBINEX_HOME/scripts/softmask2hardmask.py --input_file ref.genome.softmask.relabel.fa --output_file ref.genome.hardmask.relabel.fa

# Setting up index
$SAMTOOLS_DIR/samtools faidx ref.genome.hardmask.relabel.fa

# Converting the hard masked fasta file into a 2bit file and extracting the masking information into a bed file
$UCSC_DIR/faToTwoBit -long -noMask ref.genome.hardmask.relabel.fa ref.genome.hardmask.relabel.2bit
$UCSC_DIR/twoBitInfo -nBed ref.genome.hardmask.relabel.2bit ref.genome.hardmask.relabel.masking_details.bed

# Determine the GC range for FREEC
python $RECOMBINEX_HOME/scripts/prepare_genome_for_FREEC.py --input ref.genome.raw.relabel.fa --prefix ref --excluded_list "$excluded_chr_list_for_cnv_profiling"

# Creating index of FREEC.fa file
$SAMTOOLS_DIR/samtools faidx ref.FREEC.fa

$BEDTOOLS makewindows -g ref.FREEC.fa.fai -w $window_size > ref.FREEC.window.$window_size.bed
$BEDTOOLS nuc -fi ref.FREEC.fa -bed ref.FREEC.window.$window_size.bed > ref.FREEC.GC_content.txt




