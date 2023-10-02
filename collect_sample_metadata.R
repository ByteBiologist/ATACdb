library(rvest)
library(tibble)

extract_data <- function(sample_number) {
  # Construct the URL with the provided sample number
  url <- paste0("https://bio.liclab.net/ATACdb/search/search_sample_result.php?get_sample_id=", sample_number)

  # Read the webpage
  webpage <- read_html(url)

  # Find all the tables on the webpage
  tbls <- html_nodes(webpage, "table")

  # Extract the first table
  tbls_ls <- tbls[[1]] %>% html_table()

  # Create a tibble with custom column names
  tbls_ls <- as_tibble(tbls_ls)
  colnames(tbls_ls) <- c("Key", "Value")

  # Extracting values for specific attributes
  sample_id <- tbls_ls$Value[tbls_ls$Key == "Sample ID:"]
  biosample_type <- tbls_ls$Value[tbls_ls$Key == "Biosample type:"]
  tissue_type <- tbls_ls$Value[tbls_ls$Key == "Tissue type:"]
  biosample_name <- tbls_ls$Value[tbls_ls$Key == "Biosample name:"]
  cancer_type <- tbls_ls$Value[tbls_ls$Key == "Cancer type:"]
  region_number <- tbls_ls$Value[tbls_ls$Key == "Region number:"]
  length <- tbls_ls$Value[tbls_ls$Key == "Length:"]
  geo_sra <- tbls_ls$Value[tbls_ls$Key == "GEO/SRA ID:"]

  # Create a data frame with the extracted data
  sample_data <- data.frame(
    Sample_ID = sample_id,
    Biosample_Type = biosample_type,
    Tissue_Type = tissue_type,
    Biosample_Name = biosample_name,
    Cancer_Type = cancer_type,
    Region_Number = region_number,
    Length = length,
    GEO_SRA = geo_sra
  )

  return(sample_data)
}

# Initialize an empty data frame to store all the results
all_sample_data <- data.frame()

# Iterate through sample IDs from 1 to 1500
for (sample_number in 1:1500) {
  sample_data <- extract_data(sample_number)
  all_sample_data <- rbind(all_sample_data, sample_data)
}

# Write all the data to a single text file without quotes
write.table(all_sample_data, "samples_metadata.txt", sep = "\t", row.names = FALSE, quote = FALSE)

