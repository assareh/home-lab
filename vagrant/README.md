# Vagrantfile for single node Vault Server

The first time you run this, you'll want to initialize Vault and create a new Raft cluster.

If desired you could use [synced folders](https://www.vagrantup.com/docs/synced-folders) to sync the Vault data from the guest to the host.

## Steps
You can use Vagrant to set up a Vault server virtual machine. Vagrant is
a tool for building and managing virtual machine environments.

~> **NOTE**: To use the Vagrant environment, first install Vagrant following
these [instructions](https://www.vagrantup.com/docs/installation/). You also
need a virtualization tool, such as [VirtualBox](https://www.virtualbox.org/).

From a terminal in this folder, you may create the virtual machine with the `vagrant up` command.

```shell-session
$ vagrant up
```

This takes a few minutes as the base Ubuntu box must be downloaded
and provisioned with Vault. Once this completes, you should see this output.

```plaintext hideClipboard
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'hashicorp/bionic64'...
==> default: Running provisioner: shell...
```

Once this provisioning completes, use the `vagrant ssh` command to start a shell session on it.

```shell-session
$ vagrant ssh
```

If you connect to the virtual machine properly, you should find yourself at a
shell prompt for `vagrant@vault:~$`

## Accessing the environment

You may view the Vault interface with a web browser. Please access here:
- Vault UI https://localhost:8200/

A certificate warning is expected as we are using the default self-signed certificate. 

*Note*: If this page does not load, please check your Vagrant output. If there is a port collision on your system Vagrant may assign a different port.

## Cleaning up

### Halt the VM

Exit any shell sessions that you made to the virtual machine. Use the `vagrant halt` command to stop the running VM.

```shell-session
$ vagrant halt
```

At this point, you can start the VM again without having to provision it.

### De-provision the VM

If you want to destroy the machine and all of its data, use the `vagrant destroy` command to deprovision the environment you created. The command verifies that you intend to perform this activity; enter `Y` at the prompt to confirm that you do.

```shell-session
$ vagrant destroy
```

```plaintext
    default: Are you sure you want to destroy the 'default' VM? [y/N] y
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...
```

De-provisioning the environment deletes the VM that was created based on the base
box.

### Remove the base box

If you don't intend to use the Vagrant environment ever again, you can also
delete the downloaded Vagrant base box used to create the VM by running the
`vagrant box remove` command. Don't worry, if you decide to use the environment
again later, Vagrant re-downloads the base box when you need it.

```shell-session
$ vagrant box remove hashicorp/bionic64
```

```plaintext
Removing box 'hashicorp/bionic64' (v1.0.282) with provider 'virtualbox'...
```

At this point, you have removed all of the parts that are added by starting up
the Vagrantfile.