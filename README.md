# Custom ubuntu-server 20.04.6 live-iso

This repo is a playground to modify a ubuntu-server 20.04.6 live-iso. You can
create/update the liveiso with th configured playground.

## Requirements

- [vagrant](https://www.vagrantup.com/)
- [virtualbox](https://www.virtualbox.org/)

## Limitation

For now you can use it only with `x64` system since the VM images are not compatible
with `ARM` or others architectures.

## Getting started

To create a liveiso you can just run the following script:

```bash
$ ./scripts/create-live-iso.sh
```

This will generate a custom `live-iso` in 
`build-custom-iso/custom-ubuntu-20.04.6-live-server-amd64.iso`.

Afterwards, you can test this `live-iso` using vagrant:

```bash
$ vagrant up
```

A GUI of a VM will launch and you can perform an installation on this VM.

## Clean files

If you tried to perform installation locally and have generated files on your
system you can clean it with:

```bash
$ ./scripts/clean.sh
```

## Shutdown VMs

To shutdown all VMs you can execute:

```bash
$ ./scripts/down.sh
```

# License

[MIT](./LICENSE)
