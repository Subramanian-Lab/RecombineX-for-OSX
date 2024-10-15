"""
This code contains some functions that are called by all the scripts commonly so kept it here for easy maintenance
"""

# Importing necessary packages
import os
import sys

# Function to check the existence of a file
def testing_file_existence(input_file):
    if not os.path.exists(input_file):
        print(f"File {input_file} does not exist")
        sys.exit(1)


