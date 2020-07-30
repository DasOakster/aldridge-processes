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
# The Channel is "Web Enabled"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "4dWWFuLV6FRGBR4aP9X1SyTDUHiU5F4ha6oL5ZNO1meY7mpTyp6WsUj5ZAsuy8tZ"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"

#--------------------------------------------------------------------------------------------------------------

# Update Web Enabled Parent

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

# Create the Web Enabled B2B update data (Var WebEnabled Flag = TRUE)
parent.B2B.flag <- filter(product.data, Attribute == "VAR WEBENABLED" & Value == 1)
parent.B2B.flag <- parent.B2B.flag[,c(4,3)]


# Create the Web Enabled B2C update data (Either var Web Enabled Flag or Var Flag B2C = TRUE)
parent.B2C.flag <- filter(product.data, Attribute == "VAR FLAG B2C" & Value == 1)
parent.B2C.flag <- parent.B2C.flag[,c(4,3)]
parent.B2C.flag <- rbind(parent.B2B.flag, parent.B2C.flag)

# Create a File to Unrelease the Variants from the Channel
variant.flag <- data.frame(unique(product.data$Primary.ID))
variant.flag$flag <- Sys.Date()


#--------------------------------------------------------------------------------------------------------------
# Upload Parent Flag Changes
#--------------------------------------------------------------------------------------------------------------

put.attribute.data(parent.B2B.flag,"PRODWEBENABLEDB2B",feed.token)
put.attribute.data(parent.B2C.flag,"PRODWEBENABLEDB2C",feed.token)
put.attribute.data(variant.flag,"varWebEnabledFlag",feed.token)
