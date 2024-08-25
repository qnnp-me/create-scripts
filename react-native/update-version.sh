#!/bin/bash

PROJECT_NAME=""
RNDIR_NAME=""

SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")
WORKDIR=$(pwd)

# Check the number of arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 [major|minor|patch]"
  exit 1
fi

# Parse the argument
case "$1" in
major | minor | patch)
  version="$1"
  ;;
*)
  echo "Usage: $0 [major|minor|patch]"
  exit 1
  ;;
esac

BASIC_DIR=$(dirname "$BASEDIR")

# Read the package.json file
package_info_file="${BASIC_DIR}/package.json"

# Extract the current version and build from the package.json
current_version=$(jq -r '.version' "$package_info_file")
current_build=$(jq -r '.build' "$package_info_file")

# Split the version into an array
IFS='.' read -r -a version_parts <<<"$current_version"
IFS=' ' read -r -a build <<<"$current_build"

# Increment the version parts based on the argument
case "$version" in
major)
  ((version_parts[0]++))
  version_parts[1]=0
  version_parts[2]=0
  ;;
minor)
  ((version_parts[1]++))
  version_parts[2]=0
  ;;
patch)
  ((version_parts[2]++))
  ;;
esac

# Increment the build number
((build[0]++))

# Construct new version and build strings
new_version="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
new_build="${build[0]}"

# Update the package.json file using jq
jq --arg new_version "$new_version" --arg new_build "$new_build" \
  '.version = $new_version | .build = $new_build' \
  "$package_info_file" >temp && mv temp "$package_info_file"

# Update the android/app/build.gradle file
file_path="${BASIC_DIR}/android/app/build.gradle"
if [ -f "$file_path" ]; then
  # Replace the version name
  sed -i '' -E "s|versionName \"[^\"]+\"|versionName \"${new_version}\"|g" "$file_path"
  # Replace the version code
  sed -i '' -E "s|versionCode [0-9]+|versionCode ${new_build}|g" "$file_path"
fi

# Update the ios/PrivacyManager.xcodeproj/project.pbxproj file
file_path="${BASIC_DIR}/ios/${PROJECT_NAME}.xcodeproj/project.pbxproj"
if [ -f "$file_path" ]; then
  # Replace the marketing version
  sed -i '' -E "s|MARKETING_VERSION = [^;]+;|MARKETING_VERSION = ${new_version};|g" "$file_path"
  # Replace the current project version
  sed -i '' -E "s|CURRENT_PROJECT_VERSION = [^;]+;|CURRENT_PROJECT_VERSION = ${new_build};|g" "$file_path"
fi
