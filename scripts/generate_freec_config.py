import sys

def write_freec_config(refseq_tag, preprocessing_dir, ploidy, threads, min_map, min_gc, max_gc, window, step, mates_orientation, output_file):
    with open(output_file, 'w') as f:
        f.write("### For more options see: http://boevalab.com/FREEC/tutorial.html#CONFIG ###\n")
        f.write("[general]\n")
        f.write(f"bedtools = /path/to/bedtools\n")  # Set paths appropriately
        f.write(f"samtools = /path/to/samtools\n")
        f.write(f"maxThreads = {threads}\n")
        f.write(f"chrLenFile = ./{preprocessing_dir}/{refseq_tag}.FREEC.fa.fai\n")
        f.write(f"chrFiles = ./{preprocessing_dir}/{refseq_tag}_FREEC_chr\n")
        f.write("telocentromeric = 0\n")
        f.write(f"ploidy = {ploidy}\n")
        f.write(f"gemMappabilityFile = ./{preprocessing_dir}/{refseq_tag}.FREEC.mappability\n")
        f.write(f"minMappabilityPerWindow = {min_map}\n")
        f.write(f"minExpectedGC = {min_gc}\n")
        f.write(f"maxExpectedGC = {max_gc}\n")
        f.write(f"window = {window}\n")
        f.write(f"step = {step}\n")
        f.write("breakPointThreshold = 1.2\n")
        f.write("breakPointType = 2\n")
        f.write("[sample]\n")
        f.write("inputFormat = BAM\n")
        f.write("mateFile = FREEC.bam\n")
        f.write(f"matesOrientation = {mates_orientation}\n")

if __name__ == "__main__":
    refseq_tag = sys.argv[1]
    preprocessing_dir = sys.argv[2]
    ploidy = sys.argv[3]
    threads = sys.argv[4]
    min_map = sys.argv[5]
    min_gc = sys.argv[6]
    max_gc = sys.argv[7]
    window = sys.argv[8]
    step = sys.argv[9]
    mates_orientation = sys.argv[10]
    output_file = sys.argv[11]

    write_freec_config(refseq_tag, preprocessing_dir, ploidy, threads, min_map, min_gc, max_gc, window, step, mates_orientation, output_file)

