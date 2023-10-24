#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

rm -rf build-custom-iso/*.iso \
    build-custom-iso/autoinstall-ISO \
