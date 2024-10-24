#!/bin/zsh
set -e -o pipefail

# Loading environment variables
source ./../../env.sh
source ./../../build/conda/etc/profile.d/conda.sh
source ./../../build/conda/etc/profile.d/mamba.sh
mamba activate recombinex_venv

########### Setting project specific variables ############
parent1_tag="S288C" # The unique tag of parental genome 1 for downstream analysis
parent2_tag="SK1" # The unique tag of parental genome 2 for downstream analysis

# The path to parental genomes
parent1_reads_R1="./../00.Parent_Reads/$parent1_tag.R1.fq.gz"
parent1_reads_R2="./../00.Parent_Reads/$parent1_tag.R2.fq.gz"
parent2_reads_R1="./../00.Parent_Reads/$parent2_tag.R1.fq.gz"
parent2_reads_R2="./../00.Parent_Reads/$parent2_tag.R2.fq.gz"

use_centromere_annotation="yes" # Whether to use centromere annotation. enabling yes requires parent1_tag.centromere.relabel.gff and paren2_tag.centromere.relabel.gff (Set this option to "no" while running for mitochondrial genome)
apply_CNV_filter="yes" # Whether to apply CNV filter marker candidates. Set this option to "no" when running RecombineX for the mitochondrial genome due to its substantial GC% bias and highly repetitive content. Default = "yes". 
ploidy=1 # The ploidy of the parental genome. (e.g. "1" for haploid and "2" for diploid). For diploid parents, only homozygous SNPs will be used as markers. If the parental genome is purely homozygous, it is recommended to set "ploidy=1" to maximize the power of CNV profiling. Default = "1".
window_size=250 # The window size for the non-overlapping sliding-window-based CNV profiling. Default = 250 (i.e. 250 bp). 
threads=4 # The number of threads to use. Default = "4"
debug="no" # Whether to keep intermediate files for debugging.

# Processing the pipeline
reference_genome_preprocessing_dir="./../01.Reference_Genome_Preprocessing" # The path to the 01.Reference_Genome_Preprocessing dir.
reference_raw_assembly="$reference_genome_preprocessing_dir/ref.genome.raw.relabel.fa" # The relabelled reference genome
reference_hardmask_bed="$reference_genome_preprocessing_dir/ref.genome.hardmask.relabel.masking_details.bed" # The masking details bed file for the relabelled and hardmasked reference genome assembly file generated in the 01.Reference_Genome_Preprocessing directory.

mapping_quality_cutoff=30 # The minimal mapping quality to be considered. Default = "30".
variant_calling_quality_cutoff=30 # The minimal variant calling quality to be considered. Default = "30"

min_mappability=0.85 # The minimal mappability for sliding-window-based CNV profiling. Default = "0.85"
cluster_window_size=10 # Adjacent variants within the specified window (unit:bp) will be filtered out if any of them is INDEL. Default = "10".

excluded_chr_list_for_cnv_profiling="" # The relative path to the list for specifying chromosomes/scaffolds/contigs to be exclued for CNV profiling. Default = "".

###########################################################

test_file_existence () {
    filename=$1
    if [[ ! -f $filename ]]
    then
        echo "the file $filename does not exists! process terminated!"
        exit
    else
	echo "test pass."
    fi
}

echo ""
echo "check the existence of reference_raw_assembly: $reference_raw_assembly"
test_file_existence $reference_raw_assembly
echo ""
echo "check the existence of reference_hardmask_bed: $reference_hardmask_bed"
test_file_existence $reference_hardmask_bed

if [[ $use_centromere_annotation == "yes" ]]
then
    reference_centromere_gff="$reference_genome_preprocessing_dir/ref.centromere.relabel.gff"
    echo ""
    echo "check the existence of reference_centromere_gff: $reference_centromere_gff"
    test_file_existence $reference_centromere_gff
fi

echo ""
echo "check the existence of genome1_reads_R1: $parent1_reads_R1"
test_file_existence $parent1_reads_R1
echo ""
echo "check the existence of parent1_reads_R2: $parent1_reads_R2"
test_file_existence $parent1_reads_R2
echo ""
echo "check the existence of parent2_reads_R1: $parent2_reads_R1"
test_file_existence $parent2_reads_R1
echo ""
echo "check the existence of parent2_reads_R2: $parent2_reads_R2"
test_file_existence $parent2_reads_R2
echo ""

reference_based_output_dir="${parent1_tag}-${parent2_tag}_Reference_based"
mkdir $reference_based_output_dir

cd $reference_based_output_dir

ln -s ./../$reference_raw_assembly ref.genome.raw.fa
ln -s ./../$parent1_reads_R1 $parent1_tag.R1.raw.fq.gz
ln -s ./../$parent1_reads_R2 $parent1_tag.R2.raw.fq.gz
ln -s ./../$parent2_reads_R1 $parent2_tag.R1.raw.fq.gz
ln -s ./../$parent2_reads_R2 $parent2_tag.R2.raw.fq.gz

adapter="$TRIMMOMATIC/adapters/TruSeq3-PE-2.fa"
cp $adapter adapter.fa

mkdir tmp

# index reference sequence
$SAMTOOLS_DIR/samtools faidx ref.genome.raw.fa
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -XX:ParallelGCThreads=$threads -jar $PICARD_DIR/picard.jar CreateSequenceDictionary  \
    -REFERENCE ref.genome.raw.fa \
    -OUTPUT ref.genome.raw.dict
$BWA_DIR/bwa index ref.genome.raw.fa

# trim the reads
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -XX:ParallelGCThreads=$threads -jar $TRIMMOMATIC/trimmomatic.jar PE -threads $threads -phred33 $parent1_tag.R1.raw.fq.gz $parent1_tag.R2.raw.fq.gz $parent1_tag.R1.trimmed.PE.fq.gz $parent1_tag.R1.trimmed.SE.fq.gz $parent1_tag.R2.trimmed.PE.fq.gz $parent1_tag.R2.trimmed.SE.fq.gz ILLUMINACLIP:adapter.fa:2:30:10  SLIDINGWINDOW:5:20 MINLEN:36

if [[ $debug == "no" ]]
then
    rm $parent1_tag.R1.trimmed.SE.fq.gz
    rm $parent1_tag.R2.trimmed.SE.fq.gz
fi

# Map reads to the reference genome
$BWA_DIR/bwa mem -t $threads -M ref.genome.raw.fa $parent1_tag.R1.trimmed.PE.fq.gz $parent1_tag.R2.trimmed.PE.fq.gz | $SAMTOOLS_DIR/samtools view -bS -q $mapping_quality_cutoff -F 3340 -f 2 - >${parent1_tag}-ref.ref.bam

if [[ $debug == "no" ]]
then
    rm $parent1_tag.R1.trimmed.PE.fq.gz
    rm $parent1_tag.R2.trimmed.PE.fq.gz
fi

# Sorting bam file by picard tools SortSam
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -XX:ParallelGCThreads=$threads -jar $PICARD_DIR/picard.jar SortSam \
    -INPUT ${parent1_tag}-ref.ref.bam \
    -OUTPUT ${parent1_tag}-ref.ref.sort.bam \
    -SORT_ORDER coordinate

if [[ $debug == "no" ]]
then
    rm ${parent1_tag}-ref.ref.bam
fi

# Fix mate
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -XX:ParallelGCThreads=$threads -jar $PICARD_DIR/picard.jar FixMateInformation \
    -INPUT ${parent1_tag}-ref.ref.sort.bam \
    -OUTPUT ${parent1_tag}-ref.ref.fixmate.bam \

if [[ $debug == "no" ]]
then
    rm ${parent1_tag}-ref.ref.sort.bam
fi

# Add or replace read groups and sort
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -XX:ParallelGCThreads=$threads -jar $PICARD_DIR/picard.jar AddOrReplaceReadGroups \
    -INPUT ${parent1_tag}-ref.ref.fixmate.bam \
    -OUTPUT ${parent1_tag}-ref.ref.rdgrp.bam \
    -SORT_ORDER coordinate \
    -RGID "$parent1_tag" \
    -RGLB "$parent1_tag" \
    -RGPL illumina \
    -RGPU "$parent1_tag" \
    -RGSM "$parent1_tag" \
    -RGCN "RGCN"

if [[ $debug == "no" ]]
then
    rm ${parent1_tag}-ref.ref.fixmate.bam
fi

# Remove duplicates
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -XX:ParallelGCThreads=$threads -jar $PICARD_DIR/picard.jar MarkDuplicates \
    -INPUT ${parent1_tag}-ref.ref.rdgrp.bam \
    -REMOVE_DUPLICATES true \
    -METRICS_FILE ${parent1_tag}-ref.ref.dedup.metrics \
    -OUTPUT ${parent1_tag}-ref.ref.dedup.bam \

# Index the dedup.bam file
$SAMTOOLS_DIR/samtools index ${parent1_tag}-ref.ref.dedup.bam

if [[ $debug == "no" ]]
then
    rm ${parent1_tag}-ref.ref.rdgrp.bam
fi

## GATK local realign

# Find realigner targets
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -XX:ParallelGCThreads=$threads -jar $GATK3/gatk3.jar \
    -nt $threads \
    -R ref.genome.raw.fa \
    -T RealignerTargetCreator \
    -I ${parent1_tag}-ref.ref.dedup.bam \
    -o ${parent1_tag}-ref.ref.realn.intervals 

echo "Check 2"
# run realigner
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -XX:ParallelGCThreads=$threads -jar $GATK3/gatk3.jar  \
    -R ref.genome.raw.fa -T IndelRealigner \
    -I ${parent1_tag}-ref.ref.dedup.bam -targetIntervals ${parent1_tag}-ref.ref.realn.intervals  \
    -o ${parent1_tag}-ref.ref.realn.bam

if [[ $debug == "no" ]]
then
    rm ${parent1_tag}-ref.ref.dedup.bam
    rm ${parent1_tag}-ref.ref.dedup.bam.bai
    rm ${parent1_tag}-ref.ref.dedup.metrics
    rm ${parent1_tag}-ref.ref.realn.intervals
fi

# Generate SAMtools mpileup
$SAMTOOLS_DIR/samtools mpileup -C 0 -q $mapping_quality_cutoff -f ref.genome.raw.fa ${parent1_tag}-ref.ref.realn.bam |gzip -c >${parent1_tag}-ref.ref.mpileup.gz

# Calculate per-base depth
$SAMTOOLS_DIR/samtools depth -aa ${parent1_tag}-ref.ref.realn.bam | gzip -c >${parent1_tag}-ref.ref.depth.txt.gz

# Compute basic alignment statistics by samtools
$SAMTOOLS_DIR/samtools flagstat ${parent1_tag}-ref.ref.realn.bam >${parent1_tag}-ref.ref.samstat

# Compute insert size statistics
$JAVA_DIR/java -Djava.io.tmpdir=./tmp -XX:ParallelGCThreads=$threads -jar $PICARD_DIR/picard.jar CollectInsertSizeMetrics \
    I=${parent1_tag}-ref.ref.realn.bam \
    O=${parent1_tag}-ref.ref.insert_size_metrics.txt \
    H=${parent1_tag}-ref.ref.insert_size_histogram.pdf \
    M=0.5

# Calculating read mapping coverage statistics
python $RECOMBINEX_HOME/scripts/summarize_mapping_coverage.py \
    --genome_file ref.genome.raw.fa \
    --samstat_file ${parent1_tag}-ref.ref.samstat \
    --depth_file ${parent1_tag}-ref.ref.depth.txt.gz \
    --min_depth_cutoff 5 \
    --tag $parent1_tag \
    --output_file ${parent1_tag}-ref.ref.coverage_summary.txt

# Scan for CV using FREEC
parent1_raw_read_length=100
step_size=$window_size
min_expected_gc=$(cat ./../$reference_genome_preprocessing_dir/ref.FREEC.GC_range.txt | egrep -v "#" | cut -f 1)
max_expected_gc=$(cat ./../$reference_genome_preprocessing_dir/ref.FREEC.GC_range.txt | egrep -v "#" | cut -f 2)
echo "min_expected_gc=$min_expected_gc, max_expected_gc=$max_expected_gc";

