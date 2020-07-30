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
# The Channel is "Admin Parent Brand"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "D7PD9ppKuOmL76Xn4IivjKEcEEyOBnaOS87fIi9awJdT01vEwhjaMGlqrlimY4OH"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"

#--------------------------------------------------------------------------------------------------------------

# Update Parent Flag Process

#--------------------------------------------------------------------------------------------------------------
# Get Data for Process
#--------------------------------------------------------------------------------------------------------------

# Download the Items to update
get.channel.data(channel.token, pim.env, link = "Parent")
# Remove temporary objects
remove("pim.data")

#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Process
#--------------------------------------------------------------------------------------------------------------

# Create the Brand update data
parent.brand <- filter(product.data, Attribute == "Brand")
parent.brand <- unique(parent.brand[,c(4,3)])

# Create the data to unrelease the variants from the channel
product.data$parentBrandChange <- Sys.Date()
variant.update <- unique(product.data[,c(1,5)])

#--------------------------------------------------------------------------------------------------------------
# Upload Parent Flag Changes
#--------------------------------------------------------------------------------------------------------------

put.attribute.data(parent.brand,"PRODBRAND",feed.token)
put.attribute.data(variant.update,"parentBrandChange",feed.token)
