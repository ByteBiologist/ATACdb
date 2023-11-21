import os
import subprocess

# Function to perform bedtools intersect
def perform_bedtools_intersect(motif_file, input_file, output_file):
    cmd = [
        "bedtools",
        "intersect",
        "-a", motif_file,
        "-b", input_file,
        "-wo"
    ]
    with open(output_file, "w") as output:
        process = subprocess.run(cmd, stdout=subprocess.PIPE, text=True)
        
        # Define the header
        header = "#chrom\tstart\tend\tname\tscore\tstrand\tmotif_id\tpValue\tqValue\tbinding_sequence\topen_chromatin_region"
        
        # Write the header to the output file
        output.write(header + '\n')
        
        for line in process.stdout.split('\n'):
            if line:
                # Split the line into columns
                columns = line.split('\t')
                
                # Format columns 11, 12, and 13 as "chr1:10006-10614"
                coordinates = f"{columns[10]}:{columns[11]}-{columns[12]}"
                
                # Concatenate columns starting from the 14th column using ';'
                concatenated_columns = ";".join([coordinates] + columns[13:])
                
                # Replace the columns in the output line
                modified_line = "\t".join(columns[:10] + [concatenated_columns])
                
                # Write the modified line to the output file
                output.write(modified_line + '\n')
    
    #print(f"Intersection complete for {input_file}. Results saved to {output_file}")

    # Bgzip the output file
    bgzip_cmd = ["bgzip", output_file]
    subprocess.run(bgzip_cmd)

    print(f"Intersection complete for {input_file}. Results saved to {output_file}.gz")


# Load samples metadata into a dictionary (Sample_ID -> Tissue_Type)
samples_metadata = {}
with open("samples_metadata.txt", "r") as metadata_file:
    for line in metadata_file:
        if not line.startswith("Sample_ID"):
            columns = line.strip().split("\t")
            sample_id = columns[0]
            tissue_type = columns[2]
            samples_metadata[sample_id] = tissue_type

# Define the paths to the motif file and the directory containing Accessible chromatin files
motif_file = "motif_scan/Motif_scan_package_rearranged.bed"
chromatin_dir = "Accessible_chromatin_files/"
output_dir = "mapping"  # New directory for output files

# Create the "mapping" directory if it doesn't exist
if not os.path.exists(output_dir):
    os.mkdir(output_dir)

# List all the Accessible chromatin files in the directory
chromatin_files = [f for f in os.listdir(chromatin_dir) if f.endswith(".bed")]

# Loop through the chromatin files and perform bedtools intersect
for chromatin_file in chromatin_files:
    input_file = os.path.join(chromatin_dir, chromatin_file)
    
    # Extract the sample ID from the input file name (Sample_XXXX)
    sample_id = "_".join(chromatin_file.split("_")[:2])
    
    # Lookup tissue type from the samples metadata
    #if sample_id in samples_metadata:
    #    tissue_type = samples_metadata[sample_id]
    #else:
    #    tissue_type = "Unknown"  # Use "Unknown" if not found in metadata

    # Handle tissue type with multiple space-separated words
    #tissue_type = tissue_type.replace(" ", "_")
    
    # Construct the output file name
    output_file = os.path.join(output_dir, f"{sample_id}_processed.bed")
    
    # Perform bedtools intersect
    perform_bedtools_intersect(motif_file, input_file, output_file)
