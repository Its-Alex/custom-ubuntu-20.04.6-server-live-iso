#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# URLs for download
version="20.04.6"
base_url="http://releases.ubuntu.com/$version"
dest_folder="./"
iso_name="ubuntu-$version-live-server-amd64.iso"
shasum_name="SHA256SUMS"

function check_checksum {
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
}

# Download SHASUM
wget -q --show-progress "$base_url/$shasum_name" -O "$dest_folder$shasum_name"

if [[ -a "$dest_folder$iso_name" ]]; then
    # If iso exist check checksum
    check_checksum
else
    # If iso not exist download then check checksum
    wget -q --show-progress "$base_url/$iso_name" -O "$dest_folder$iso_name"
    check_checksum
fi