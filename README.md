# fhgfs-ctl-zfs-getquota

This project is intended to allow a method to collect user and group space usage across a set FhGFS storage nodes that run ZFS.

Currently the data collection method only supports storage systems with a single storage target per storage server.

## Requirements

The host that runs the collection will need root SSH access via SSH keys to the storage nodes.

The python script that parses the collected data and reports on usage requires the following modules:

* `prettytable` - EL Linux systems can install via `python-prettytable` package.
* `yaml` - **optional** EL Linux systems can install via `PyYAML` package.

If the yaml module is not installed the python script will only produce and read CSV and JSON formatted files.

## Install

Install the files to a host that will perform collection and reporting.

    make install

The files installed

* `/etc/default/fhgfs-ctl-zfs-getquota.conf` - Configuration for cron script and collector
* `/etc/cron.hourly/fhgfs_quota` - Cron script that runs the collector
* `/usr/share/fhgfs-ctl-zfs-getquota/fhgfs-ctl-zfs-getquota-collector` - Collector script that gets ZFS userspace and groupspace data
* `/usr/share/fhgfs-ctl-zfs-getquota/zfs_get_quota` - Python script that parses the collected data and also can report the data

## Usage

Once installed the collector will pull data from all storage nodes and generate a CSV and JSON formatted report for user and group usage in /tmp.

To view the report for user usage:

    /usr/share/fhgfs-ctl-zfs-getquota/zfs_get_quota report -i /tmp/fhgfs_userspace.json

To view the report for group usage:

    /usr/share/fhgfs-ctl-zfs-getquota/zfs_get_quota report -i /tmp/fhgfs_groupspace.json

The CSV formatted files can be used instead of the JSON files.

A filter of what is reported can be applied via `--names` argument.  To only show usage of users named foo and bar:

    /usr/share/fhgfs-ctl-zfs-getquota/zfs_get_quota report -i /tmp/fhgfs_userspace.json --names foo bar
