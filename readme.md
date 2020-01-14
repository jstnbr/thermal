# Thermal

Vagrant LEMP box for WordPress

> An automated WordPress development environment.

## Features

- :arrows_counterclockwise: Sync and backup database
- :zap: Code locally
- :rocket: Ship code easily
- :electric_plug: Work without internet

## Requirements

- [Vagrant](https://www.vagrantup.com "Vagrant Homepage")
- [VirtualBox](https://www.virtualbox.org "VirtualBox Homepage") (or a different provider)
- SSH access

#### SSH

Your public key is copied to Thermal on provision and is expected to be located in `~/.ssh/id_rsa.pub`. For Thermal to work, first confirm you have SSH access to the server with your key.

#### Note

- If you aren’t using a Mac, you may need to turn on virtualization in BIOS
- If you have Hyper-V on, VirtualBox will not work

## Getting Started

Install Vagrant and VirtualBox on your computer. Then install the following Vagrant plugins by running:

```
vagrant plugin install vagrant-hostsupdater
vagrant plugin install vagrant-vbguest
```

> Note: The plugin `vagrant-hostsupdater` is not required to view your project from the ip address.

## Usage

* Configure your project settings in `thermal-config.yml`.
* Run `vagrant up` from your project directory.
* View your project at `http://your-name.test`.

To run `thermal` commands SSH into the VM by running `vagrant ssh`.

## Thermal Commands

#### :mag: Check

Check the configuration.

- `backup_dir` check if backup directory exists and is writable.
- `database` check connection to the database.
- `key` show public key.
- `ssh` check SSH connection.

```
thermal check [backup_dir | database | key | ssh]
```

#### :raising_hand: Help

Show a list of available commands.

```
thermal help
```

#### :repeat: Refresh

Refresh the configuration.

```
thermal refresh
```

#### :wrench: Repair

Repair the configuration.

- `backup_dir` repair backup directory.
- `database` repair database connection.
- `permalinks` flush the permalinks.

```
thermal repair [backup_dir | database | permalinks]
```

#### :clock2: Restore

Undo the previous sync.

```
thermal restore [local | remote]
```

#### :vertical_traffic_light: Status

Check the current status.

```
thermal status
```

#### :arrows_counterclockwise: Sync

Perform a sync.

```
thermal sync [down | up]
```

Sync one part of WordPress.

```
thermal sync [database | uploads | wp-content] [down | up]
```

## Vagrant Commands

| Description | Command |
| ----------- | ------- |
| Start or resume | `vagrant up` |
| Delete | `vagrant destroy` |
| Pause | `vagrant suspend` |
| Reload | `vagrant reload` |
| SSH | `vagrant ssh` |

## Credentials

#### Database

| Description | Command |
| ----------- | ------- |
| Database | `thermal` |
| Username | `root` |
| Password | `root` |
| Hostname | `localhost` |

#### WordPress

| Description | Command |
| ----------- | ------- |
| Username | `thermal` |
| Password | `vagrant` |

#### phpMyAdmin

| Description | Command |
| ----------- | ------- |
| Username | `root` |
| Password | `root` |