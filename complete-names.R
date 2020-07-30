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

  } else{
  
  source("D:/OneDrive/Pimberly/Platform/R Development/API Library.R")
}

#--------------------------------------------------------------------------------------------------------------

# Matches a file of variants with a file of products
# Creates a new attribute combining the product name and the variant name

complete.names <- function(){
  
  # Add the Product name to the Variants data frame
  variant.names$Parent.Name <- parent.names$ProductName[match(variant.names$Parents,parent.names$Primary.ID)]
  
  # Concatenate the Product Name and variant name seperated by a hyphen
  variant.names$Complete.Name <- paste(variant.names$Parent.Name, variant.names$`Variant Name B2B`, sep = " - ")
  variant.names <- na.omit(variant.names)
  parent.update <- variant.names[,c(1,4)]
  parent.update <<- na.omit(parent.update)
  
  # Create and output the file to be imported
  complete.name <- variant.names[,c("Primary.ID","Complete.Name")]
  names(complete.name) <- c("Primary.ID","FullVarNameB2B")
  complete.name <<- complete.name
  
}

#--------------------------------------------------------------------------------------------------------------

# Constants used by the process

# This is the Aldridge Sandbox
# The Channel is "Complete Names"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "c2l8xyU5wlEyPntXkZIJjhCTL7Kxyy9Kwz9M1zit3rZIBftjZzjUIi7YIA6pw9JZ"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"

#--------------------------------------------------------------------------------------------------------------

# Complete Names Process

#--------------------------------------------------------------------------------------------------------------
# Get Data for Process
#--------------------------------------------------------------------------------------------------------------

# Download the Items to update
get.channel.data(channel.token, pim.env)

# Download the Items Parent data
parent.list <- unique(filter(product.data, Attribute == "Parents"))
get.parent.data(feed.token,pim.env, parent.list)
parent.data <- parent.data[,c(1:3)]
#-------------------------------------------------------------------------------------------------------------
# Prepare Data for Process
#--------------------------------------------------------------------------------------------------------------

# Subset the data to the Attributes for matching and processing
# Spread the data into a wide format
variant.attributes <- c("Parents", "Variant Name B2B")
variant.names <- filter(product.data, Attribute %in% variant.attributes)
variant.names <- unique(variant.names)
variant.names <- spread(variant.names, key = "Attribute", value = "Value")

parent.attributes <- c("ProductName")
parent.names <- filter(parent.data, Attribute %in% parent.attributes)
parent.names <- spread(parent.names, key = "Attribute", value = "Value")

#--------------------------------------------------------------------------------------------------------------
# Call Complete Names
#--------------------------------------------------------------------------------------------------------------

# Returns a list of Item Ids and the new FullVarNameB2B attribute value
#--------------------------------------------------------------------------------------------------------------
# Upload Complete Name Changes
#--------------------------------------------------------------------------------------------------------------

if(nrow(parent.names) > 0) {
  
  complete.names()
  # Update the FullVarName Attribute in Variant
  put.attribute.data(complete.name,"FullVarNameB2B", feed.token)
  # Update the Product Name Attribute in Variant
  put.attribute.data(parent.update,"variantNameB2B", feed.token)
  
} else {
  
  stop("No Parent Names to Apply")
  
}


# End of Process



