#!/bin/sh

set +e  # Exit on failure

# Check if docker is installed

if [ ! -x "$(command -v docker)" ]; then
    echo "docker is not installed"
    echo "installation instructions might be here: https://docs.docker.com/engine/install/"
    exit 0
fi

if [ ! -x "$(command -v git)" ]; then
    echo "Git is not installed."
    echo "Installation instructions might be here: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git"
    exit 0
fi

# Function to extract the package version from Cargo.toml
  # Use grep to find the line containing 'version' in Cargo.toml
cd src/*/rust
version_line=$(grep -E '^version = .*' Cargo.toml)

# Extract the version string after the  '='
if [ ! -z "$version_line" ]; then
    version=$(echo "$version_line" | cut -d '=' -f2 | tr -d '[:space:]')
    package_version=$(echo "$version" | sed 's/^"//' | sed 's/"$//')
else
    echo "Error: Could not find 'version' in Cargo.toml"
fi

# Extract the name from the [package] section
package_name_line=$(grep -m 1 -E '^name = .*' Cargo.toml)

# Extract the second name from the [lib] section
lib_name_line=$(grep -E '^\[lib\]' -A 5 Cargo.toml | grep -E '^name = .*')

# Extract the package name string after the '='
if [ ! -z "$package_name_line" ]; then
    package_name=$(echo "$package_name_line" | cut -d '=' -f2 | tr -d '[:space:]' | sed 's/^"//' | sed 's/"$//')
else
    echo "Error: Could not find 'name' in [package] section"
    exit 1
fi

# Extract the lib name string after the '=' if it exists
if [ ! -z "$lib_name_line" ]; then
    lib_name=$(echo "$lib_name_line" | cut -d '=' -f2 | tr -d '[:space:]' | sed 's/^"//' | sed 's/"$//')
else
    lib_name=""
fi

cd ../../../

# Print the version or handle errors
if [ ! -z "$package_version" ]; then
  :
else
  echo "An error occurred while reading the version."
  exit 1  
fi

docker build --load -t build-$target -f docker/Dockerfile.$target .
container_id=$(docker run -d "build-$target") || { echo "Failed to run container"; exit 1; }
current_dir=$(pwd)
library=$1
VERSION=${2:-"latest"}
folder_name="release/$library/$VERSION/android/$target"

if [ -d "$folder_name" ]; then
    rm -rf "$folder_name"
fi
mkdir -p "$folder_name"

if [ ! -z "$lib_name" ]; then
  a_file="/root/release/output_binaries/"
else 
  a_file="/root/release/output_binaries/"
fi


full_path="/$current_dir/$folder_name"
docker cp -a $container_id:$a_file "$full_path/" || { 
    echo "Error: Failed to copy file from container." >&2
    exit 1
}
docker kill $container_id > /dev/null 2>&1
echo "✅ x86_64-linux-android build completed! Binary in $folder_name folder."
