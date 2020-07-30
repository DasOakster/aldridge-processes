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

# Calculates the difference in days between the variant Web Enabled Date and today
web.days.live <- function(){
  
  # Perform and round the data calculation  
  variant.data$Days.Live <- round(difftime(Sys.Date(), variant.data$'Web Enabled Date', units = c("days")),0)
  
  # Subset the data by columns
  web.enabled.days <<- variant.data[, c("Primary.ID","Days.Live")]
  
}

#--------------------------------------------------------------------------------------------------------------

# Constants used by the process

# This is the Aldridge Sandbox
# The Channel is "Web New Days Live"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "NLQ5IXncvqcoCSShxYWf6CDgDw5vkpRR49g7MteQityvQq09zbCbwZ8IdXsxNKw1"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"

#--------------------------------------------------------------------------------------------------------------

# Complete Names Process

#--------------------------------------------------------------------------------------------------------------
# Get Data for Process
#--------------------------------------------------------------------------------------------------------------

# Download the Items to update
get.channel.data(channel.token, pim.env)

#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Process
#--------------------------------------------------------------------------------------------------------------

# Subset the data to the Attributes for matching and processing
# Spread the data into a wide format
variant.data <- filter(product.data, Attribute == "Web Enabled Date")
variant.data <- spread(variant.data, key = "Attribute", value = "Value")

#--------------------------------------------------------------------------------------------------------------
# Call Complete Names
#--------------------------------------------------------------------------------------------------------------

# Returns a list of Item Ids and the new FullVarNameB2B attribute value
web.days.live()

#--------------------------------------------------------------------------------------------------------------
# Upload Complete Name Changes
#--------------------------------------------------------------------------------------------------------------

put.attribute.data(web.enabled.days,"tDaysLive", feed.token)

