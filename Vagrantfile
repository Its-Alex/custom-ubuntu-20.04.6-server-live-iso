# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_version = "20231011.0.0"

  config.ssh.insert_key = false
  config.ssh.username = "ubuntu"


  config.vm.provider "virtualbox" do |vb|
    vb.gui = true

    vb.cpus = "4"
    vb.memory = "2048"

    # Enable EFI boot
    vb.customize ["modifyvm", :id, "--firmware", "efi"]
    # Add live iso from cdrom for install
    vb.customize ["storageattach", :id, "--storagectl", "IDE", "--port", "0", "--device", "1", "--type", "dvddrive", "--medium", Dir.pwd + "/build-custom-iso/custom-ubuntu-20.04.6-live-server-amd64.iso"]
  end
end
