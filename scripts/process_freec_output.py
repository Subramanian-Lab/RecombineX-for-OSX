import sys

def reformat_output(input_file, output_prefix):
    with open(input_file) as f:
        with open(f"{output_prefix}.FREEC.bam_ratio.txt", 'w') as ratio_out, open(f"{output_prefix}.FREEC.bam_CNVs.txt", 'w') as cnvs_out:
            for line in f:
                if line.startswith('#') or line.strip() == "":
                    continue
                parts = line.strip().split('\t')
                # Process the line and write to output files
                # Example processing, modify as needed
                ratio_out.write('\t'.join(parts) + '\n')
                cnvs_out.write('\t'.join(parts) + '\n')

if __name__ == "__main__":
    prefix = sys.argv[1]
    reformat_output("FREEC.bam_ratio.txt", prefix)
    reformat_output("FREEC.bam_CNVs", prefix)

