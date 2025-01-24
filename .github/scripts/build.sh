#!/bin/bash

version=$(echo $1 | grep -oP '(?<=v)\d+\.\d+\.\d+')

echo "Short version: $version"

# Create working directories if they aren't present
rm -rf build
mkdir -p build

echo "Copying files to build directory"
# Copy needed source files to the build directory
cp -r Templates build/
cp -r Workbooks build/
cp createUiDefinition.json build/
cp deploy.json build/

echo "Serializing Workbook JSON Files"
# Read the license workbook JSON file into a variable and properly escape for ARM template
license_workbook_json=$(cat 'build/Workbooks/SQL Licensing Summary.json' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | sed -e 's/\\/\\\\/g' | tr -d '\r\n')
# Repeat for Single Pane of Glass workbook
spog_workbook_json=$(cat 'build/Workbooks/Arc SQL Single Pane of Glass.json' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | sed -e 's/\\/\\\\/g' | tr -d '\r\n')

echo "Splitting Single Pane of Glass Workbook JSON into two parts for ARM Template"
echo "This uses ^ as the split character, so if this is in the JSON it will cause an issue"
# Going to change placeholder to ^ character so I can properly split, I assume this will cause me a problem in the future
spog_placeholder=$(echo $spog_workbook_json | sed 's/REPLACE_THE_LICENSE_TEMPLATE_ID/^/g')
spog_part_one=$(echo $spog_placeholder | cut -d '^' -f 1)
spog_part_two=$(echo $spog_placeholder | cut -d '^' -f 2)

echo "Replacing License Workbook JSON in Template placeholders"
# Replace Placeholder in Template with License Workbook JSON
sed -i "s^LICENSE_WORKBOOK_JSON^$license_workbook_json^g" 'build/Templates/SQL Licensing Summary.json'

echo "Replacing Single Pane of Glass Workbook JSON in Template placeholders"
# Replace Placeholders in Template with Single Pane of Glass Workbook JSON
sed -i "s^SPOG_PART_ONE^$spog_part_one^g" 'build/Templates/Arc SQL Single Pane of Glass.json'
sed -i "s^SPOG_PART_TWO^$spog_part_two^g" 'build/Templates/Arc SQL Single Pane of Glass.json'

echo "Replacing version in ARM Templates so they all match"
sed -i "s/\"contentVersion\": \"1.0.1.0\"/\"contentVersion\": \"$version.0\"/g" 'build/deploy.json'
sed -i "s/\"contentVersion\": \"1.0.1.0\"/\"contentVersion\": \"$version.0\"/g" 'build/Templates/Arc SQL Single Pane of Glass.json'
sed -i "s/\"contentVersion\": \"1.0.1.0\"/\"contentVersion\": \"$version.0\"/g" 'build/Templates/SQL Licensing Summary.json'

echo "Replacing URIs in deploy.json with the correct release URIs"

sed -i "s^\"uri\":\"Templates/SQL%20Licensing%20Summary.json\"^\"uri\":\"https://github.com/$2/releases/download/$1/SQL%20Licensing%20Summary.json\"^g" 'build/deploy.json'
sed -i "s^\"uri\":\"Templates/Arc%20SQL%20Single%20Pane%20of%20Glass.json\"^\"uri\":\"https://github.com/$2/releases/download/$1/Arc%20SQL%20Single%20Pane%20of%20Glass.json\"^g" 'build/deploy.json'