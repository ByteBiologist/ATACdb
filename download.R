# Define the URL of the BED file
url <- "https://bio.liclab.net/ATACdb/download/download_car_bed/Sample_0001.bed"

# Extract the filename from the URL
filename <- basename(url)

# Download the BED file from the URL and save it with the extracted filename
download.file(url, destfile = filename)