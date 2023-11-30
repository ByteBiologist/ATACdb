# Function to perform bedtools intersect
perform_bedtools_intersect <- function(motif_file, input_file, output_file) {
  # Construct the bedtools intersect command
  cmd <- c("bedtools", "intersect", "-a", motif_file, "-b", input_file, "-wo")

  # Run the bedtools intersect command and capture the output
  intersect_output <- system2(cmd, stdout = TRUE)

  # Split the output by newline character
  output_lines <- strsplit(intersect_output, "\n")[[1]]

  # Open the output file for writing
  output_conn <- file(output_file, "w")

  # Process each line and modify it as needed
  for (line in output_lines) {
    if (line != "") {
      # Split the line by tab character
      columns <- strsplit(line, "\t")[[1]]
      
      # Format columns 11, 12, and 13 as "chr1:10006-10614"
      coordinates <- paste0(columns[11], ":", columns[12], "-", columns[13])
      
      # Concatenate columns starting from the 14th column using ';'
      concatenated_columns <- paste(coordinates, paste(columns[14:length(columns)], collapse = ";"), sep = "\t")
      
      # Write the modified line to the output file
      cat(concatenated_columns, file = output_conn, append = TRUE)
    }
  }

  # Close the output file
  close(output_conn)

  cat("Intersection complete for", input_file, ". Results saved to", output_file, "\n")
}

# Load samples metadata from "samples_metadata.txt" into a list
samples_metadata <- list()
metadata_file <- file("samples_metadata.txt", "r")
while (length(line <- readLines(metadata_file, n = 1)) > 0) {
  # Split the line into columns using tab as separator
  columns <- strsplit(line, "\t")[[1]]
  sample_id <- columns[1]
  tissue_type <- columns[3]
  samples_metadata[[sample_id]] <- tissue_type
}
close(metadata_file)

# Define the paths to the motif file, the directory containing Accessible chromatin files, and the output directory
motif_file <- "motif_scan/Motif_scan_package_rearranged.bed"
chromatin_dir <- "Accessible_chromatin_files/test"
output_dir <- "mapping"  # New directory for output files

# Create the "mapping" directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# List all the Accessible chromatin files in the directory
chromatin_files <- list.files(path = chromatin_dir, pattern = "\\.bed$")

# Loop through the chromatin files and perform bedtools intersect
for (chromatin_file in chromatin_files) {
  input_file <- file.path(chromatin_dir, chromatin_file)

  # Extract the sample ID from the input file name (Sample_XXXX)
  sample_id <- gsub("_.*", "", chromatin_file)

  # Lookup tissue type from the samples metadata
  tissue_type <- samples_metadata$Tissue_Type[samples_metadata$Sample_ID == sample_id]

  # If not found, use "Unknown"
  if (length(tissue_type) == 0) {
    tissue_type <- "Unknown"
  }

  # Construct the output file name
  output_file <- file.path(output_dir, paste0(sample_id, "_", tissue_type, "_processed.bed"))

  # Perform bedtools intersect
  perform_bedtools_intersect(motif_file, input_file, output_file)
}
