#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# URLs for download
version="20.04.6"
base_url="http://releases.ubuntu.com/$version"
dest_folder="./"
iso_name="ubuntu-$version-live-server-amd64.iso"
shasum_name="SHA256SUMS"

# Download ISO and SHASUM
wget -q --show-progress "$base_url/$iso_name" -O "$dest_folder$iso_name"
wget -q --show-progress "$base_url/$shasum_name" -O "$dest_folder$shasum_name"

# Check checksum
checksum=$(sha256sum "$dest_folder$iso_name" | awk '{print $1}')
expected_checksum=$(grep "ubuntu-$version-live-server-amd64.iso" "$dest_folder$shasum_name" | awk '{print $1}')

rm -rf "$dest_folder$shasum_name"

if [[ "$checksum" == "$expected_checksum" ]]; then
    echo "Checksum ok!"
else
    echo "Invalid checksum!"
    exit 1
fi
