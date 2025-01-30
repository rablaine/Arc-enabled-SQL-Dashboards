#!/bin/bash

# Create datetime string for upload
datetime=$(date '+%Y%m%d%H%M%S')

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
license_workbook_json=$(cat 'build/Workbooks/SQLLicensingSummary.json' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | sed -e 's/\\/\\\\/g' | tr -d '\r\n')
# Repeat for Single Pane of Glass workbook
spog_workbook_json=$(cat 'build/Workbooks/ArcSQLSinglePaneofGlass.json' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | sed -e 's/\\/\\\\/g' | tr -d '\r\n')

echo "Splitting Single Pane of Glass Workbook JSON into two parts for ARM Template"
echo "This uses ^ as the split character, so if this is in the JSON it will cause an issue"
# Going to change placeholder to ^ character so I can properly split, I assume this will cause me a problem in the future
set -f
spog_placeholder=$(echo $spog_workbook_json | sed 's/REPLACE_THE_LICENSE_TEMPLATE_ID/^/g')
spog_part_one=$(echo $spog_placeholder | cut -d '^' -f 1)
spog_part_two=$(echo $spog_placeholder | cut -d '^' -f 2)
set +f

echo "Replacing License Workbook JSON in Template placeholders"
# Replace Placeholder in Template with License Workbook JSON
sed -i "s^LICENSE_WORKBOOK_JSON^$license_workbook_json^g" 'build/Templates/SQLLicensingSummary.json'

echo "Replacing Single Pane of Glass Workbook JSON in Template placeholders"
# Replace Placeholders in Template with Single Pane of Glass Workbook JSON
sed -i "s^SPOG_PART_ONE^$spog_part_one^g" 'build/Templates/ArcSQLSinglePaneofGlass.json'
sed -i "s^SPOG_PART_TWO^$spog_part_two^g" 'build/Templates/ArcSQLSinglePaneofGlass.json'

echo "Replacing URIs in deploy.json with the correct release URIs"

sed -i "s^\"uri\":\"Templates/SQLLicensingSummary.json\"^\"uri\":\"https://arcdashprupload.blob.core.windows.net/dev/$datetime/SQLLicensingSummary.json\"^g" 'build/deploy.json'
sed -i "s^\"uri\":\"Templates/ArcSQLSinglePaneofGlass.json\"^\"uri\":\"https://arcdashprupload.blob.core.windows.net/dev/$datetime/ArcSQLSinglePaneofGlass.json\"^g" 'build/deploy.json'

sleep 1

rm -rf build/upload
mkdir -p build/upload

mkdir -p "build/upload/$datetime"

echo "Copying files to build/upload directory"
cp -r build/Templates/* "build/upload/$datetime/"
cp build/deploy.json "build/upload/$datetime/"
cp build/createUiDefinition.json "build/upload/$datetime/"

echo "output=Generated ARM Template available at https://arcdashprupload.blob.core.windows.net/dev/$datetime/deploy.json for 90 days" >> $GITHUB_ENV