# Thermal

Vagrant LAMP box for WordPress

> An automated WordPress development environment.

## Features

- :arrows_counterclockwise: Sync and backup database
- :zap: Code locally
- :rocket: Ship code easily
- :electric_plug: Work without internet

## Getting Started

Install [Vagrant](https://www.vagrantup.com "Vagrant Homepage") and [VirtualBox](https://www.virtualbox.org "VirtualBox Homepage") on your computer. Then install the following Vagrant plugins by running:

```
vagrant plugin install vagrant-hostsupdater
vagrant plugin install vagrant-vbguest
```

> Note: The plugin `vagrant-hostsupdater` is not required to view your project from the ip address.

## Usage

* Configure your project settings in `thermal-config.yml`.
* Run `vagrant up` from your project directory.
* View your project at `http://your-name.test`.

SSH into the VM by running `vagrant ssh` to run `thermal` commands.

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

| Command | Description |
| ------- | ----------- |
| `vagrant up` | Start or resume |
| `vagrant destroy` | Delete |
| `vagrant suspend` | Pause |
| `vagrant reload` | Reload |
| `vagrant ssh` | SSH |

## Credentials

##### Database

| Command | Description |
| ------- | ----------- |
| `thermal` | Database |
| `root` | Username |
| `root` | Password |
| `localhost` | Hostname |

##### WordPress

| Command | Description |
| ------- | ----------- |
| `thermal` | Username |
| `vagrant` | Password |