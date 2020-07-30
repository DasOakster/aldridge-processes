#--------------------------------------------------------------------------------------------------------------

# Clean up workspace for testing

# Test Commit 
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

# MixMatch flags the Parent Product as either MixMatch Multi or MixMatch Multi depending on the distrbution of Aggregate codes amongst variants
# The flags set are PROD_MIX_FLAG and PROD_MIX_MULTI_FLAG

mixMatch <- function(){
  
  # Get a list of all the Aggregate Codes
  aggregate.codes <- unique(variant.aggregate$Aggregate.Code)
  
  # Add columns to hold the flags
  variant.aggregate$'Mix.Multi' <- NA
  variant.aggregate$'Mix.Single' <- NA
  
  # Iterate through the list of aggregate codes
  for(i in 1:length(aggregate.codes)){
    
    # Subset by the Aggregate Code
    mix.match.data <- subset(variant.aggregate, Aggregate.Code == aggregate.codes[i])
    
    # Count the number of Parents an Aggregate Code has
    mix.match.count <- data.frame(table(mix.match.data$Parent.ID))
    
    # If the Aggregate Code has more than one parent it is a Mix Multi
    if(nrow(mix.match.count) > 1){
      
      
      variant.aggregate$Aggregate.Multi <- mix.match.data$Aggregate.Code[match(variant.aggregate$Primary.ID,mix.match.data$Primary.ID)]
      variant.aggregate <- within(variant.aggregate, Mix.Multi[!is.na(Aggregate.Multi)] <- TRUE )
      
      
      # If the Aggregate Code has only one parent is is a Mix Single    
    } else if(nrow(mix.match.count == 1)) {
      
      variant.aggregate$Aggregate.Single <- mix.match.data$Aggregate.Code[match(variant.aggregate$Primary.ID,mix.match.data$Primary.ID)]
      variant.aggregate <- within(variant.aggregate, Mix.Single[!is.na(Aggregate.Single)] <- TRUE )
      
    }
    
    
    
  }
  
  # Return the updated Variant Aggregate data frame
  variant.aggregate <<- variant.aggregate
  
}
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

# Constants used by the process

# This is the Aldridge Sandbox
# The feed is "Feed API"
pim.env <- "Sandbox"
feed.token <- "HG7jqH9deEU6EzJhKoqX6UEZ5FwSO55ul7MZ063Cb8FbBL62WxMVJ6im9ZemwlaA"
ftp.site <- "ftp://pimberly-9fcuev:bmTyakXoAzUTqTTa4ieb@ftp.pimberly.com/data/Aldridge/Scripted Process/"

#--------------------------------------------------------------------------------------------------------------

# Mix Match Process

#--------------------------------------------------------------------------------------------------------------
# Get Data for Process
#--------------------------------------------------------------------------------------------------------------

# Download the Items to update
message("Downloading PIM Data")
get.feed.data(feed.token, pim.env)
# Remove temporary objects
remove("pim.data")

# **********************************************************************************************************************************************

#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Mix Match Process
#--------------------------------------------------------------------------------------------------------------

message("Running Mix Match")
# Create the data

# Get any variants that have an aggregate code
message("Getting Aggregate Codes")
variant.aggregate <- filter(product.data, product.data$Attribute == "tAggregateCode")
variant.aggregate <- variant.aggregate[!(variant.aggregate$Value == "N"),]

# Match these variants to their parents:  creates 'Parent Data'
message("Creating Parent Data")
get.product.parents(feed.token,pim.env, variant.aggregate)

if(exists("parent.data")) {
      
      item.parent <- unique(parent.data[,c("Primary.ID","Item.ID")])
      variant.aggregate$Parent.ID <- item.parent$Primary.ID[match(variant.aggregate$Primary.ID, item.parent$Item.ID)]
      variant.aggregate <- variant.aggregate[,c(4,1,3)]
      names(variant.aggregate) <- c("Parent.ID","Primary.ID", "Aggregate.Code")
      
      # Get any products with Mix Match flags set at either Product or Variant level
      # These are set to false before running the Mix Match process
      message("Setting Existing Mix Match Flags to FALSE")
      mix.match.extant <- filter(product.data, grepl("VARFLAGMIX|PROD_MIX",product.data$Attribute))
      mix.match.extant <- mix.match.extant[(mix.match.extant$Value == TRUE),]
      mix.match.extant$Value <- gsub("TRUE","FALSE",mix.match.extant$Value)
      put.multi.attribute.data(mix.match.extant, feed.token)
      
      # Call the Mix Match Function
      # Updates the variant.aggregate dataframe with additionall flags for updating
      message("Creating the Mix Match Update File")
      mixMatch()
      
      # Upload Parent Flag Changes
      message("Updating the Parent Mix Match Flags")
      mix.match.update <- unique(variant.aggregate[,c("Parent.ID", "Mix.Multi", "Mix.Single")])
      names(mix.match.update) <- c("Primary.ID", "PROD_MIX_MULTI_FLAG", "PROD_MIX_FLAG")
      mix.match.update <- melt(mix.match.update, id.vars = "Primary.ID", na.rm = TRUE)
      put.multi.attribute.data(mix.match.update, feed.token)
      
      # Upload Variant Flag Changes
      message("Updating the Variant Mix Match Flags")
      mix.match.variant.update <- unique(variant.aggregate[,c("Primary.ID", "Mix.Multi", "Mix.Single")])
      names(mix.match.variant.update) <- c("Primary.ID", "VARFLAGMIXMULTI", "VARFLAGMIX")
      mix.match.variant.update <- melt(mix.match.variant.update, id.vars = "Primary.ID", na.rm = TRUE)
      put.multi.attribute.data(mix.match.variant.update, feed.token)

# **********************************************************************************************************************************************
      }

message("Mix Match Completed")

#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Associate Products Process
#--------------------------------------------------------------------------------------------------------------

# Filter any products with associated variant SKUs
simple.products.match <- filter(product.data, (grepl("ASSVARSKU", product.data$Attribute)))

# Get a list of the internal product ids
product.id <- filter(product.data, Attribute == "id")

# Match on interna IDs to get the Primary ID of the associated variant SKUs
simple.products.match$Assc.ID <- product.id$Primary.ID[match(simple.products.match$Value, product.id$Value)]

# Get Parent Information for Variants

# Subset the Variants and Associated Variants
simple.id <- unique(simple.products.match$Primary.ID)
simple.assc.id <- unique(simple.products.match$Assc.ID)
simple.products <- as.data.frame(c(simple.id, simple.assc.id))
names(simple.products) <- "Item.ID"

# Get the parent ids of the Variants
get.product.parents(feed.token, pim.env, simple.products, parent.id.only = TRUE)

if(exists("parent.data")) {
    # Match back to the Parent.Data file
    simple.products.match$Primary.ID.Parent <- parent.data$Primary.ID[match(simple.products.match$Primary.ID, parent.data$Item.ID )]
    simple.products.match$Assc.ID.Parent <- parent.data$Primary.ID[match(simple.products.match$Assc.ID, parent.data$Item.ID )]
    
    # Create the Update File
    associate.products <- na.omit(simple.products.match[,c(5,6)])
    names(associate.products) <- c("Primary.ID", "ASS_ASSPRODSKU")
    
    # Output the data as a file and upload to the FTP location for the feed
    setwd(output.file.dir)
    
    write.xlsx(associate.products, "Parent Associated Products.xlsx")
    
    ftpUpload("Parent Associated Products.xlsx",paste0(ftp.site,"Parent Associated Products.xlsx"))

}
# **********************************************************************************************************************************************

#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Search Attributes Process
#--------------------------------------------------------------------------------------------------------------

 search.attributes <- function() {   
   
   # Subset data to relevant attributes
    product.search.attributes <- filter(product.data, (grepl("ProductAttributeDropDown", product.data$Attribute)))
    # Subset the Parent IDs
    parents.to.match <- as.data.frame(unique(product.search.attributes$Primary.ID))
    # Subset the product data to a unique list of IDs to iterate through
    products <- unique(product.search.attributes$Primary.ID)
    
    
    # Get the Item Data for these products
    get.product.items(feed.token,pim.env,parents.to.match)
    
    
    if(exists("item.data")) {
        
          for(i in 1:length(products)){
          
          # Gets the Search Attributes for the Product
          search.attributes <- filter(product.search.attributes, Primary.ID == products[i])[,3]
          
          # Gets the Item data for the Product
          item.search.data <- subset(item.data, item.data$Parent.ID == products[i])
          # Changes the Item data attribute names to lower case for matching to the Pimberly dataset (created by Adridge in lower case)
          item.search.data$Attribute <- lapply(item.search.data$Attribute, function(x) tolower(x))
          # Subset the item data to the search attributes
          item.search.data <- subset(item.search.data, item.search.data$Attribute %in% search.attributes)
          
          
          item.search.data <- spread(item.search.data, key = "Attribute", value = "Value")
          
          # Check the Item Search Data for any missing values or duplicate combinations
          
          # Identify any missing attributes to flag and exclude
          
          # Attributes Missing Values
          item.search.data$missing <- apply(item.search.data, 1, function(x) sum(is.na(x)))
          item.search.data.missing <- subset(item.search.data, missing > 0)
          
          if(nrow(item.search.data.missing) > 0){
            
            if(exists("item.missing")) {
              
              item.missing <- bind_rows(item.missing, item.search.data.missing)
              
              
            } else {
              
              item.missing <- item.search.data.missing
              
            }
            
          }
          
          if(exists("item.missing")) item.missing <- item.missing[,c(2,1)]
          
          # Remove Missing for the Duplicates Check
          item.search.data <- subset(item.search.data, missing == 0)
          item.search.data <- subset(item.search.data, select= -c(missing))
          
          # Create the Matchkey on the data fields  - Exclude the 2 ID columns
          cols.to.merge <- which(!(grepl("[.ID]$",names(item.search.data))), useNames = TRUE)
          
          # Merge the columns to a new attribute
          item.search.data$matchkey <- apply(item.search.data[,cols.to.merge] ,1, paste, collapse = "-" )
          
          # Check the matchkey for duplication
          item.search.dupes <- item.search.data[duplicated(item.search.data$matchkey),]
          
          # Extract any duplicated search combinations
          dupe.keys <- unique(item.search.dupes$matchkey)
          item.search.dupes <- subset(item.search.data, item.search.data$matchkey %in% dupe.keys)
          item.search.dupes <- item.search.dupes[,c("Parent.ID","Primary.ID")] 
          
          # Build the data frame of duplicated
          if(exists("item.duplicated")) {
            
            item.duplicated <- bind_rows(item.duplicated, item.search.dupes)
            
            
          } else {
            
            item.duplicated <- item.search.dupes
            
          }
          
          
          }  # End of loop
        
        # Output the data as a file and upload to the FTP location for the feed
        setwd(output.file.dir)
        
        write.xlsx(item.missing, "Search Attribute Missing.xlsx")
        write.xlsx(item.duplicated, "Search Attribute Dupe.xlsx")
        
        ftpUpload("Search Attribute Missing.xlsx",paste0(ftp.site,"Search Attribute Missing.xlsx"))
        ftpUpload("Search Attribute Dupe.xlsx",paste0(ftp.site,"Search Attribute Dupe.xlsx"))
    
    }
        
    message("Associated Products Completed")
    
}

# **********************************************************************************************************************************************


#--------------------------------------------------------------------------------------------------------------
# Prepare Data for Product Flag process - Nulls any Parent Flags if Variants have been switched off
#--------------------------------------------------------------------------------------------------------------

message("Running the Parent Flag Process")
# Get All Variant Flag values

# List of variant flags for use in RegEx
variant.flag.check <- "VARFLAGPROMO|VARFLAGCLEARANCE|VARFLAGNEW|VAR_FLAG_FEATURED|productDiscontinued|VARFLAGB2C|VARWEBENABLED"

# List of flags to rseset Product FLags to False
product.flag.list <- c("PROD_CLEARANCEFLAG","PROD_PROMOFLAG","PROD_NEWFLAG","PROD_FEATUREDFLAG","productDiscontinued","PRODFLAGB2C","PRODWEBENABLEDB2B")
variant.flag.list <- c("VARFLAGCLEARANCE","VARFLAGPROMO","VARFLAGNEW","VAR_FLAG_FEATURED,","productDiscontinued","VARFLAGB2C","VARWEBENABLED")
flag.list <- data.frame(cbind(variant.flag.list,product.flag.list))

message("Get Variants with Flags")
variant.flags <- product.data[grep(variant.flag.check, product.data$Attribute),]
variant.flags <- variant.flags[variant.flags$Value == TRUE,]
variant.id <- data.frame(unique(variant.flags$Primary.ID))

message("Get Parent IDs")
# Get and map the parent id fields
get.product.parents(feed.token, pim.env, variant.id, parent.id.only = TRUE)
variant.flags$Parent.ID <- parent.data$Primary.ID[match(variant.flags$Primary.ID, parent.data$Item.ID)]

# Subset to only variants with matched parents
variant.flags <- variant.flags[!(is.na(variant.flags$Parent.ID)),]

# --------------------------------------------------------------------------------------------------------------
# Set all Parent Flags to False
# --------------------------------------------------------------------------------------------------------------

message("Set all Parent Flags to FALSE")
# Get Parent IDs to set to False
parent.id <- data.frame(unique(variant.flags$Parent.ID))
parent.id$flag <- FALSE

# Set Parent IDs to False for any Flag in the list
for(i in 1:length(product.flag.list)){

  put.attribute.data(parent.id,product.flag.list[i], feed.token)

}
# --------------------------------------------------------------------------------------------------------------

# Update Parent Flags to True based on Variant Flag
# Any variant flag set to TRUE sets the Parent

message("Update Parent Flags")
for(i in 1:nrow(flag.list)) {
  
  # Subset the variants and parents where variant flag is TRUE
  variant.flag <- filter(variant.flags, Attribute == flag.list[i,1])
  
  if(nrow(variant.flag) > 0) {
  
      # Add the Parent Flag to update
      variant.flag$Parent.Flag <- flag.list[i,2]
      
      # Subset parent update data
      parent.flag <- unique(variant.flag[,c(4,3)])
      
      # Update Pimberly - Uses the Flag list to select the attribute to update
      put.attribute.data(parent.flag,flag.list[i,2], feed.token)
  
  }
  
}

message("Product Flag Process Complete")
# --------------------------------------------------------------------------------------------------------------

