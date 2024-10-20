"""
This calculates the GC range for the genome sequence for FREEC
"""

# Importing necessary packages
import pandas as pd
import numpy as np
from Bio import SeqIO
import argparse

# Input handling
parser = argparse.ArgumentParser(description="Calculating GC statistics")

parser.add_argument("--input_file", type=str, help="Input GC content file")
parser.add_argument("--output_file", type=str, help="Output GC range file")
parser.add_argument("--window_size", type=int, help="Window Size")
parser.add_argument("--lower_quantile", type=float, help="Lower Quantile")
parser.add_argument("--upper_quantile", type=float, help="Upper Quantile")
parser.add_argument("--min_mappability", type=float, help="Minimum mappability")

args = parser.parse_args()
gc_content_file = args.input_file
output_gc_range_file = args.output_file
window_size = args.window_size
lower_quantile = args.lower_quantile
upper_quantile = args.upper_quantile
min_mappability = args.min_mappability


# Calculating the GC statistics
def computing_gc_statistics(df):
    gc_statistics = {}

    for chr_name, group in df.groupby("chr"):
        # Calculating aggregated statistics for each chromosomes
        group["AT_count"] = group["A_count"] + group["T_count"]
        group["GC_count"] = group["G_count"] + group["C_count"]
        group["effective_window_size"] = group["AT_count"] + group["GC_count"]
        group["effective_ratio"] = group["effective_window_size"] / window_size

        effective_gc_values = group.loc[group["effective_ratio"] > min_mappability, "GC_count"] / group[
            "effective_window_size"]
        effective_gc_values = effective_gc_values.dropna()

        if len(effective_gc_values) >= 10:
            gc_statistics[chr_name] = {
                "min_gc": effective_gc_values.min(),
                "max_gc": effective_gc_values.max(),
                "lower_quantile": np.percentile(effective_gc_values, lower_quantile),
                "upper_quantile": np.percentile(effective_gc_values, upper_quantile)
            }

    return gc_statistics


# Running the program
column_header = ["chr", "window_start", "window_end", "AT_pct", "GC_pct", "A_count", "C_count", "G_count", "T_count",
                 "N_count", "other_count", "window_seq_length"]
with open(gc_content_file, "rt") as gc_file:
    df = pd.read_csv(gc_file, sep="\t", comment="#", names=column_header)

# Obtaining the GC statistics
gc_statistics = computing_gc_statistics(df)

# Writing the minimum and maximum expected GC values into a txt file
with open(output_gc_range_file, "wt") as output_handle:
    output_handle.write("#min_expected_gc\tmax_expected_gc\n")
    min_expected_gc = min(stat["lower_quantile"] for stat in gc_statistics.values())
    max_expected_gc = max(stat["upper_quantile"] for stat in gc_statistics.values())

    output_handle.write(f"{min_expected_gc:.3f}\t{max_expected_gc:.3f}")
