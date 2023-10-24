# Build custom iso

This folder is dedicated for custom `ubuntu-server 20.04.6 live-iso`. All VMs
and scripts in this folder will only be used to generated and modify live-iso.

## Requirements

- [vagrant](https://www.vagrantup.com/)
- [virtualbox](https://www.virtualbox.org/)

## How to launch and enter in VM

We use vagrant to perform actions, this way we can use it on any distribution.

First, launch the VM with vagrant:

```bash
$ vagrant up
```

Needed packages are installed directly with [`the provisionning`](./Vagrantfile#6).

Next you can enter in the VM:

```bash
$ vagrant ssh
```

Two folders exists:

1. `/vagrant`
1. `/workdir`

1. `/vagrant` folder

This folder is synced with [./ of the host](./). And is used to transfer files
between VMs and host.

2. `/workdir` folder

This folder is used to run scripts in the VM it's a copy of `/vagrant` folder at
[`the boot of the VM`](./Vagrantfile#13). You can recreate the folder, with
those commands outisde the VM:

```bash
vagrant ssh -c "sudo rm -rf /workdir && sudo cp -r /vagrant /workdir"
```

## Scripts

All scripts can be found in [`./scripts`](./scripts/). Those scripts are made to
be launched in the VM.

## Limitation

Don't run scripts that play with [`mount`](https://linux.die.net/man/8/mount),
[`squashfs`](https://en.wikipedia.org/wiki/SquashFS) or others tools that play
with symbolic links in synced folders. (https://www.virtualbox.org/ticket/10085)
