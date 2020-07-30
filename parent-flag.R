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
  
  source("D:/OneDrive/Pimberly/Platform/R Development/API Library.r")
}


#--------------------------------------------------------------------------------------------------------------

# Constants used by the process

# This is the Aldridge Sandbox
# The Channel is "Variant Flag"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "dEQUALidwM4mKTJr5kdj6D4nenT8BayT7qLlThTK30QkOEUAbJ8YUqQZHJaGBQsf"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"

#--------------------------------------------------------------------------------------------------------------

# Update Parent Flag Process

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

# Create the data - Product flags are 1 and 0, Heavy / Long is text
variant.flags <- product.data[grep("Parents|^PROD.*FLAG$", product.data$Attribute),]
variant.flag.update <- filter(variant.flags, Value == 1)
parent.id <- variant.flags[grep("Parents", variant.flags$Attribute),]

heavy.long.flag.update <- filter(variant.flags, grepl("Heavy|Long", variant.flags$Value))
heavy.long.flag.update$Parent.ID <- parent.id$Value[match(heavy.long.flag.update$Primary.ID, parent.id$Primary.ID)]
heavy.long.flag.update <- unique(heavy.long.flag.update[,c(4,3)])

# Match and Subset
variant.flag.update$Parent.ID <- parent.id$Value[match(variant.flag.update$Primary.ID, parent.id$Primary.ID)]
variant.flag.update <- unique(variant.flag.update[,c(4,2,3)])

# Set Variant Date Change to Unrelease from Channel
variant.unrelease <- data.frame(unique(product.data$Primary.ID))
variant.unrelease$update.date <- Sys.Date()


#--------------------------------------------------------------------------------------------------------------
# Upload Parent Flag Changes
#--------------------------------------------------------------------------------------------------------------

put.multi.attribute.data(variant.flag.update,feed.token)
put.attribute.data(heavy.long.flag.update,"productAwk", feed.token)
put.attribute.data(variant.unrelease,"varVariantFlag", feed.token)


