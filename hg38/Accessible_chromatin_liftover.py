#!/usr/bin/python
import os
import subprocess

# Define base directory where liftover tool and chain file are located
base_dir = "/mnt/ebs/jackal/FILER2/FILER2-production/ATACdb/"

# Define liftover path and chain file relative to the base directory
liftover_path = os.path.join(base_dir, "Liftover/liftOver")
chain_file = os.path.join(base_dir, "Liftover/hg19ToHg38.over.chain.gz")

# Check and filter on chromosome start
def filter_bed_file(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for idx, line in enumerate(infile):
            if idx == 0:
                continue
            
            fields = line.strip().split('\t')
            start_position = fields[1]
            
            try:
                int(start_position)
                outfile.write(line)
            except ValueError:
                continue

def liftover_bed(input_file, destination_dir):
    base_name = os.path.basename(input_file).split('.')[0]
    filtered_input_file = os.path.join(destination_dir, "filtered", f"{base_name}_filtered.bed")
    filter_bed_file(input_file, filtered_input_file)
    
    output_file = os.path.join(destination_dir, f"{base_name}_hg38_lifted.bed")
    unlifted_dir = os.path.join(destination_dir, "unlifted")
    os.makedirs(unlifted_dir, exist_ok=True)
    unlifted_path = os.path.join(unlifted_dir, f"{base_name}_unlifted.bed")
    
    # Command for liftover
    cmd = [
        liftover_path,
        "-bedPlus=6",
        filtered_input_file,
        chain_file,
        output_file,
        unlifted_path
    ]
    
    try:
        subprocess.run(cmd, check=True)
        print(f"Liftover for {input_file} completed successfully.")
        
        # Read header from input file
        with open(input_file, 'r') as f_in:
            header = f_in.readline().strip()
        
        # Add header to lifted-over output file
        with open(output_file, 'r+') as f_out:
            content = f_out.read()
            f_out.seek(0, 0)
            f_out.write(header + '\n' + content)
        
    except subprocess.CalledProcessError as e:
        print(f"Error during liftover for {input_file}: {e}")
        raise
    
    return output_file

def process_directory(input_dir, output_dir):
    # Iterate over all files in the input directory
    for filename in os.listdir(input_dir):
        if filename.endswith(".bed"):
            input_file = os.path.join(input_dir, filename)
            liftover_bed(input_file, output_dir)

# Example usage:
input_directory = "/mnt/ebs/jackal/FILER2/FILER2-production/ATACdb/Accessible_chromatin_files"
output_directory = "/mnt/ebs/jackal/FILER2/FILER2-production/ATACdb/hg38/liftover_accessible_chromatin"
process_directory(input_directory, output_directory)
