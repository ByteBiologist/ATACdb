process_sample <- function(sample_id) {
  # Format the sample ID with leading zeros
  formatted_sample_id <- sprintf("%04d", sample_id)

  print(formatted_sample_id)
  # Define the URL of the BED file for the given sample_id
  url <- paste0("https://bio.liclab.net/ATACdb/download/download_car_bed/Sample_", formatted_sample_id, ".bed")

  # Extract the filename from the URL
  filename <- basename(url)

  # Define the directory paths for raw and processed files
  raw_download_dir <- "raw_download/"
  processed_dir <- "Accessible_chromatin_files/"

  # Ensure that the directories exist; create them if they don't
  dir.create(raw_download_dir, showWarnings = FALSE, recursive = TRUE)
  dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)

  # Check if the raw BED file already exists in the raw_download directory
  if (!file.exists(file.path(raw_download_dir, filename))) {
    # Download the BED file from the URL and save it to the raw_download directory
    download.file(url, destfile = file.path(raw_download_dir, filename))

    # Check if the file has been downloaded successfully
    if (file.exists(file.path(raw_download_dir, filename))) {
      cat("Raw BED file downloaded successfully for Sample_", sample_id, ".\n")
    } else {
      cat("Failed to download the raw BED file for Sample_", sample_id, ".\n")
      return(NULL)  # Return NULL to indicate an error
    }
  } else {
    cat("Raw BED file for Sample_", sample_id, " already exists in the raw_download directory.\n")
  }

  # Read the BED file into a data frame
  bed_data <- read.table(file.path(raw_download_dir, filename), header = TRUE, sep = "\t")

  # Rename the columns with special characters
  colnames(bed_data)[7] <- "score"
  colnames(bed_data)[9] <- "pValue"
  colnames(bed_data)[10] <- "qValue"
  colnames(bed_data)[11] <- "peak"

  # Create placeholder columns for "name" and "strand"
  bed_data$name <- NA
  bed_data$strand <- NA

  # Subtract 1 from the "start" column
  #bed_data$start <- bed_data$start - 1

  # Create a new data frame with the desired column order
  rearranged_bed_data <- bed_data[, c("chr", "start", "end", "name", "score", "strand", "fold_change", "pValue", "qValue", "peak", "sample_ID", "region_ID")]

  # Define the output filename for the rearranged BED file
  output_filename <- file.path(processed_dir, paste0("Sample_", formatted_sample_id, "_rearranged.bed"))

  # Write the modified data frame to a new BED file in the Accessible_chromatin_files directory
  write.table(rearranged_bed_data, file = output_filename, sep = "\t", quote = FALSE, row.names = FALSE)

  cat("Rearranged BED file saved as", output_filename, "\n")
  
  # Return the path to the rearranged BED file
  return(output_filename)
}

# Loop through sample numbers from 1 to 1493
for (sample_number in 1:1493) {
  result <- process_sample(sample_number)
  if (!is.null(result)) {
    cat("Processing for Sample_", sprintf("%04d", sample_number), " completed successfully.\n")
    cat("Processed BED file saved as", result, "\n")
  } else {
    cat("Processing for Sample_", sprintf("%04d", sample_number), " encountered an error.\n")
  }
}



