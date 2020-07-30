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
library(reshape2)


#--------------------------------------------------------------------------------------------------------------

# Functions used by the process

# Removes HTML tags from text
unescape_html <- function(str){
  xml2::xml_text(xml2::read_html(paste0("<x>", str, "</x>")))
}
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
# The Channel is "Product Description"
# The feed is "Feed API"
pim.env <- "Sandbox"
channel.token <- "jrXvLSAahpMK7u6Z9r0OTytwhUDs52DJg6LZ94uv1ORgJY3S2vVMsPdPMJGIaoPe"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"

#--------------------------------------------------------------------------------------------------------------

# Update HTML Strip Process

#--------------------------------------------------------------------------------------------------------------
# Get Data for Process
#--------------------------------------------------------------------------------------------------------------

# Download the Items to update
get.channel.data(channel.token, pim.env)
# Remove temporary objects
remove("pim.data")

    #--------------------------------------------------------------------------------------------------------------
    # Create Clean Versions of the Description for Product and Variant
    #--------------------------------------------------------------------------------------------------------------


# Checks that there is a least 1 item to update

    
    
    clean.description <- filter(product.data, Attribute == "Description")
    #clean.description$html.strip <- unescape_html(clean.description$Value)
    clean.description$html.strip <- sapply(clean.description$Value,unescape_html)
    
    # Create Parent Clean Description Update
    
    message("Processing Parent Data")
    parent.description <- clean.description[,c(1,4)]
    parent.description <- unique(parent.description)
    
    if(nrow(parent.description) > 0) {
      
      put.attribute.data(parent.description,"PRODSUMMARYCLEAN",feed.token)
      get.product.items(feed.token, pim.env, parent.description, item.id.only = TRUE)
    
    }  else {
      
      message("No Parent Descriptions to Process")
    }
      
    
    if(exists("item.data")) {
          
          message("Processing Item Data")
          item.data$description <- clean.description$Value[match(item.data$Parent.ID, clean.description$Primary.ID)]
          item.data$html.strip <- parent.description$html.strip[match(item.data$Parent.ID, parent.description$Primary.ID)]
              
          # Creat Variant Clean Description
          variant.clean.description <- item.data[,c(1,6)]
              
          # Creat Variant copy of raw Description
          variant.description <- item.data[,c(1,5)]
              
          #--------------------------------------------------------------------------------------------------------------
          # Upload Parent Flag Changes
          #--------------------------------------------------------------------------------------------------------------
          
          put.attribute.data(variant.clean.description,"VARDESCRIPTIONCLEAN",feed.token)
          put.attribute.data(variant.description,"VAR_DESCRIPTION",feed.token)

      } else {
            
      message("No Items to Process")
      
      }
    
message("Product Descriptions Completed")