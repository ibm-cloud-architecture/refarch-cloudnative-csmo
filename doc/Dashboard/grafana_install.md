# Introduction
[Grafana](http://grafana.org) is one of the leading tools for querying and visualizing time series and metrics. In the CSMO project we used it to create dashboards for First Responder persona. 
Grafana features a variety of panels, including fully featured graph panels with rich visualization options. There is built in support for many of the time series data sources like InfluxDB or Graphite. We used InfluxDB - a time series database for metrics as a data source for Grafana and perl script to collect data from various APIs of BlueCompute CSMO infrastructure like New Relic, Bluemix, NOI or CMDB.

# Installing Grafana on Centos 7

## Download

Description | Download
------------ | -------------
Stable .RPM for CentOS | [3.1.1 (x86-64 rpm)](https://grafanarel.s3.amazonaws.com/builds/grafana-3.1.1-1470047149.x86_64.rpm)

## Install Latest Stable

You can install Grafana using Yum directly.

    $ sudo yum install https://grafanarel.s3.amazonaws.com/builds/grafana-3.1.1-1470047149.x86_64.rpm

## Package details

- Installs binary to `/usr/sbin/grafana-server`
- Copies init.d script to `/etc/init.d/grafana-server`
- Installs default file (environment vars) to `/etc/sysconfig/grafana-server`
- Copies configuration file to `/etc/grafana/grafana.ini`
- Installs systemd service (if systemd is available) name `grafana-server.service`
- The default configuration uses a log file at `/var/log/grafana/grafana.log`
- The default configuration specifies an sqlite3 database at `/var/lib/grafana/grafana.db`


## Start the server (via systemd)

    $ sudo systemctl daemon-reload
    $ sudo systemctl start grafana-server
    $ sudo systemctl status grafana-server

### Enable the systemd service to start at boot

    sudo systemctl enable grafana-server.service

## Environment file

The systemd service file and init.d script both use the file located at
`/etc/sysconfig/grafana-server` for environment variables used when
starting the back-end. Here you can override log directory, data
directory and other variables.

### Logging

By default Grafana will log to `/var/log/grafana`

### Database

The default configuration specifies a sqlite3 database located at
`/var/lib/grafana/grafana.db`. Please backup this database before
upgrades. 

## Configuration

The configuration file is located at `/etc/grafana/grafana.ini`.  Go the
[Configuration](http://docs.grafana.org/installation/configuration) page for details on all
those options.

### Adding data sources

- [InfluxDB]






