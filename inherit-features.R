#--------------------------------------------------------------------------------------------------------------

# Clean up workspace for testing
remove(list = ls())

# Libraries used by the Aldridge processes

library(plyr)
library(httr)
library(jsonlite)
library(openxlsx)
library(tidyverse)
library(RCurl)


#--------------------------------------------------------------------------------------------------------------

# Functions used by the process

#--------------------------------------------------------------------------------------------------------------

# Set up the file paths depedent on OS
if(.Platform$OS.type == "unix") {
  
  source("/home/andyo/R-scripts/api-library.R")
  output.file.dir <- "/home/andyo/R-scripts/"

  } else{
  
  source("D:/OneDrive/Pimberly/Platform/R Development/API Library.r")
  output.file.dir <- "D:/OneDrive/Pimberly/Clients/Aldridge/Aldridge Working Directory/Upload Files/"
}


#--------------------------------------------------------------------------------------------------------------

# Matches a file of variants with a file of products
# Creates a new attribute combining the product name and the variant name
# Creates a file of the changes and upoads this to the FTP site for import by the Complete Names channel
# Inherit Features Function
# Links the Product features to the each Item id

inherit.features <- function(){
  
  # Matches the feature data from the Parent product to the variant products
  # Creates 2 files - B2B and B2C for uploading via FTP
  
  for(i in 1:nrow(product.feature.item)){
    
    # Create the B2B Item File
    # Get the item and parent id
    product.id <- as.character(product.feature.item[i,2])
    item.id <- as.character(product.feature.item[i,1])
    
    b2b.feature.data <- subset(product.feature.B2B, product.feature.B2B$`Primary.ID` == product.id)
    b2b.feature.data$`Primary.ID` <- item.id
    
    #  On the first run it will create the permaenent data frame
    if(exists("item.features.b2b")) {
      
      item.features.b2b <- rbind(item.features.b2b, b2b.feature.data)
      
      
    } else {
      
      item.features.b2b <- b2b.feature.data

    }
    
    # Create the B2C Item File
    product.id <- as.character(product.feature.item[i,2])
    item.id <- as.character(product.feature.item[i,1])
    b2c.feature.data <- subset(product.feature.B2C, product.feature.B2C$`Primary.ID` == product.id)
    b2c.feature.data$`Primary.ID` <- item.id
    
    #  On the first run it will create the permaenent data frame
    if(exists("item.features.b2c")) {
      
      item.features.b2c <- rbind(item.features.b2c, b2c.feature.data)
      
      
    } else {
      
      item.features.b2c <- b2c.feature.data
      
    }
    
    # Return data to global scope
    item.features.b2b <<- item.features.b2b
    item.features.b2c <<- item.features.b2c
    
  }
  
} # End of Function

#--------------------------------------------------------------------------------------------------------------

# Constants used by the process

# This is the Aldridge Sandbox
# The Channel is "Product Features"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "hnZ61ssY7MHOQaPU5hBhSE3Qgshs8H7EUHLofU7YBLMAqy2oLdDmqc3MrlXwAN6U"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"
ftp.site <- "ftp://pimberly-9fcuev:bmTyakXoAzUTqTTa4ieb@ftp.pimberly.com/data/Aldridge/Scripted Process/"


#--------------------------------------------------------------------------------------------------------------

# Inherit Features Process

#--------------------------------------------------------------------------------------------------------------
# Get Data for Process
#--------------------------------------------------------------------------------------------------------------

# Download the Items to update
get.channel.data(channel.token, pim.env)

# Remove temporary objects
remove("pim.data")

#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Process
#--------------------------------------------------------------------------------------------------------------

# Splits the data into a list of Item / Parent IDs and the B2B and B2C Parent Features  

# Create the Parent/Item Data
product.feature.item <- product.data[grep("Item", product.data$Attribute),]
product.feature.item <- product.feature.item[,c(3,1)]
names(product.feature.item) <- c("Primary.ID", "Parent.ID")

# Create the B2B and B2C Parent Features
product.feature.B2B <- product.data[grep("^PROD FEATURE.*B2B$", product.data$Attribute),]
product.feature.B2C <- product.data[grep("^PROD FEATURE.*B2C$", product.data$Attribute),]

#--------------------------------------------------------------------------------------------------------------
# Call Inherit Features
#--------------------------------------------------------------------------------------------------------------

# Returns a list of Item Ids and the new FullVarNameB2B attribute value

inherit.features()

#--------------------------------------------------------------------------------------------------------------
# Upload Complete Name Changes
#--------------------------------------------------------------------------------------------------------------

# Output the data as a file and upload to the FTP location for the feed
setwd(output.file.dir)

write.xlsx(item.features.b2b, "Variant Features B2B.xlsx")
write.xlsx(item.features.b2c, "Variant Features B2C.xlsx")

ftpUpload("Variant Features B2B.xlsx",paste0(ftp.site,"Variant Features B2B.xlsx"))
ftpUpload("Variant Features B2C.xlsx",paste0(ftp.site,"Variant Features B2C.xlsx"))


