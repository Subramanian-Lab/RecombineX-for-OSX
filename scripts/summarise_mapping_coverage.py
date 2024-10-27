"""
This code creates a mapping coverage file from the depth file and samstat file
"""

# Importing necessary packages
import numpy as np
from collections import defaultdict
import gzip
import argparse
from Bio import SeqIO

# Input handling
parser = argparse.ArgumentParser(description="Summarising mapping coverage")

parser.add_argument("--genome_file", type=str, help="Input genome file")
parser.add_argument("--samstat_file", type=str, help="Input samstat file")
parser.add_argument("--depth_file", type=str, help="Input depth file")
parser.add_argument("--min_depth_cutoff", type=float, help="Minimum depth cutoff")
parser.add_argument("--output_file", type=str, help="output coverage file")
parser.add_argument("--tag", type=str, help="provide genome tag")
args = parser.parse_args()

samstat_file = args.samstat_file
depth_file = args.depth_file
min_depth_cutoff = args.min_depth_cutoff
genome_file = args.genome_file
output_file = args.output_file
sample_tag = args.tag

# Parsing the genome file for chromosome ids
def parsing_genome_file(genome_file):
    seq_names = {}
    with open(genome_file, "r") as genome_handle:
        for record in SeqIO.parse(genome_file, "fasta"):
            seq_names[record.id] = record.seq
    return seq_names

# Parsting Samstat file
def parsing_samstat_file(samstat_file_path):

    first_mapping_found = False
    sam_stat = {}
    with open(samstat_file_path, "r") as samstat_handle:
        for line in samstat_handle:
            if "in total" in line:
                sam_stat["total_reads"] = sum(map(int, line.split()[0:3:2]))
            elif "mapped" in line:
                if not first_mapping_found:
                    mapped_line = line.split()[0]
                    first_mapping_found = True
            elif "properly paired" in line:
                properly_paired_line = line.split()[0]
        sam_stat["mapping_rate"] = float(mapped_line) / float(sam_stat["total_reads"])
        sam_stat["pairing_rate"] = float(properly_paired_line) / float(sam_stat["total_reads"])
    return sam_stat

# Parsting depth file
def parsing_depth_file(depth_file_path):
    zero_depth_counter = 0
    min_depth_counter = 0
    total_base_count = 0
    depth_stats = defaultdict(lambda: defaultdict(int))

    with gzip.open(depth_file_path, "rt") as depth_handle:
        for line in depth_handle:
            chr, pos, depth = line.split()
            depth = int(depth)

            if depth == 0:
                zero_depth_counter += 1
            elif depth >= min_depth_cutoff:
                min_depth_counter += 1
            
            depth_stats[chr][depth] += 1
            total_base_count += 1
    
    zero_depth_proportion = zero_depth_counter / total_base_count if total_base_count > 0 else 0
    min_depth_proportion = min_depth_counter / total_base_count if total_base_count > 0 else 0

    depth_summary = {
        "zero_depth_proportion": round(zero_depth_proportion, 2),
        "min_depth_proportion": round(min_depth_proportion, 2)
    }

    all_depths = []
    chr_depth_stats = {}

    for chr in depth_stats:
        for depth, count in depth_stats[chr].items():
            all_depths.extend([depth] * count)
            if chr not in chr_depth_stats:
                chr_depth_stats[chr] = []
            chr_depth_stats[chr].extend([depth] * count)
    
    # Calculating total mean and median
    depth_summary["mean_depth"] = round(np.mean(all_depths), 2) if all_depths else 0
    depth_summary["median_depth"] = round(np.median(all_depths), 2) if all_depths else 0

    # Calculate chromosome-wise meann and median
    for chr in chr_depth_stats:
        depth_summary[f"chr_mean_depth_{chr.strip('')}"] = round(np.mean(chr_depth_stats[chr]), 2)
        depth_summary[f"chr_median_depth_{chr.strip('')}"] = round(np.median(chr_depth_stats[chr]), 2)

    return depth_summary

def main():
    seq_names = parsing_genome_file(genome_file)
    sam_stat = parsing_samstat_file(samstat_file)
    depth_summary = parsing_depth_file(depth_file)

    with open(output_file, "w") as output_handle:
        header = ["sample", "ref_genome", "total_reads", "mapping_rate", "pairing_rate",
                  f"(>={args.min_depth_cutoff})_depth_proportion", "zero_depth_proportion",
                  "mean_depth", "median_depth"] + [f"{chr}_mean_depth" for chr in seq_names] + [f"{chr}_median_depth" for chr in seq_names]
        
        output_handle.write("\t".join(header) + "\n")

        output_row = [sample_tag, genome_file, sam_stat["total_reads"], sam_stat["mapping_rate"],
                      sam_stat["pairing_rate"], depth_summary["min_depth_proportion"], 
                      depth_summary["zero_depth_proportion"], depth_summary["mean_depth"], 
                      depth_summary["median_depth"]]
        
        for chr in seq_names:
            output_row.append(depth_summary.get(f"chr_mean_depth_{chr}"))
            output_row.append(depth_summary.get(f"chr_median_depth_{chr}"))
        
        output_handle.write("\t".join(map(str, output_row)) + "\n")

if __name__=="__main__":
    main()
    

