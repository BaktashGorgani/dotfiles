#!/bin/bash

# Target directory where the image will be saved
target_dir="/home/baky/wallpaper"

# Create the target directory if it doesn't exist
mkdir -p "$target_dir"

# API URL for Bing's Image of the Day (for Germany, change "mkt" for other regions)
api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=us"

# Fetch the JSON data from Bing's server
json_data=$(curl -s "$api_url")

# Extract the image URL, title, and location from the JSON data
image_url="https://www.bing.com$(echo $json_data | grep -oP '(?<="url":")[^"]*')"
echo $image_url
title=$(echo $json_data | grep -oP '(?<="title":")[^"]*')
location=$(echo $json_data | grep -oP '(?<="copyright":")[^,]*' | sed 's/^[^()]* (\([^)]*\)).*$/\1/')

# Extract the date (the day the image is shown)
date=$(date +%Y-%m-%d)

# Create the filename: Title + Location + Date
filename=$( echo "${title// /_}_${location// /_}_$date.jpg" | sed 's/[^a-zA-Z0-9_.-]/_/g' )

# Full path for saving the image
filepath="$target_dir/$filename"

# Download the image in maximum resolution (UHD)
echo $( curl -s -o "$filepath" "$image_url&rf=LaDigue_UHD.jpg" )

echo "Image of the Day downloaded as $filepath"
