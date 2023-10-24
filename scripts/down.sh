#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"
vagrant destroy -f

cd build-custom-iso
vagrant destroy -f
