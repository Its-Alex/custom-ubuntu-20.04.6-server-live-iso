#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../build-custom-iso"

vagrant up
vagrant ssh -c "sudo /workdir/scripts/download-ubuntu-20.04.6-server-live-iso.sh && sudo /workdir/scripts/create-live-iso.sh && sudo cp /workdir/custom-ubuntu-20.04.6-live-server-amd64.iso /vagrant"
vagrant destroy -f
