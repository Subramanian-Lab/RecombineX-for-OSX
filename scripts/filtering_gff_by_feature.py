"""
This code filters the provided gff file by feature
"""

# Importing necessary packages
import pandas as pd
import argparse

# Input handling
parser = argparse.ArgumentParser(description="filters gff file by feature")

parser.add_argument('--input_fasta', type=str, help='Input gff file')
parser.add_argument('--output_fasta', type=str, help='Output gff file')
parser.add_argument('--feature', type=str, help='Feature to filter with (default = "all")')
parser.add_argument('--mode', type=str, help='Mode of filtering (To "keep" or "remove". Default = "keep")')

args = parser.parse_args()

gff_file = args.input_fasta
output_gff_file = args.output_fasta
feature_input = args.feature
mode_of_filtering = args.mode 

# Creating Feature list
feature_list = feature_input.split()

# Setting gff column names
column_names = ["seqid", "source", "type", "start", "end", "score", "strand", "phase", "attributes"]

# Importing gff file
gff_df = pd.read_csv(gff_file, sep="\t", comment="#", header=None, names=column_names)

# Filtering gff file
if feature_input == "all":
    if mode_of_filtering == "keep":
        filtered_df = gff_df
    if mode_of_filtering == "remove":
        filtered_df = pd.DataFrame(columns=gff_df.columns)
else:
    if mode_of_filtering == "keep":
        filtered_df = gff_df[gff_df['type'].isin(feature_list)]
    elif mode_of_filtering == "remove":
        filtered_df = gff_df[~gff_df['type'].isin(feature_list)]

# Writing the filtered gff file to the output
filtered_df.to_csv(output_gff_file, sep="\t", header=False, index=False)