

#InfluxDB
[InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/) is an open-source time series database developed by InfluxData as part of their time series platform. It is written in Go and optimized for fast, high-availability storage and retrieval of time series data in fields such as operations monitoring, application metrics, Internet of Things sensor data, and real-time analytics. Here InfluxDB is used as storage for metrics collected by perl runtime and primary data source for Grafana dashboard.

## Requirements

Installation of the InfluxDB package may require `root` privileges in order to complete successfully.

### Networking

By default, InfluxDB uses the following network ports:

- TCP port `8083` is used for InfluxDB's Admin panel
- TCP port `8086` is used for client-server communication over InfluxDB's HTTP API

In addition to the ports above, InfluxDB also offers multiple plugins that may
require custom ports.
All port mappings can be modified through the [configuration file](docs.influxdata.com/influxdb/v1.0/administration/config),
which is located at `/etc/influxdb/influxdb.conf` for default installations.

## Installation

RedHat and CentOS users can install the latest stable version of InfluxDB using the `yum` package manager:

```bash
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.0.0.x86_64.rpm
sudo yum localinstall influxdb-1.0.0.x86_64.rpm
sudo systemctl start influxdb
sudo systemctl status influxdb
```

**Configure InfluxDB**

By default your config file will be at `/etc/influxdb/influxdb.conf`.  However, you can create a new config file to modify if desired.

    influx config > influxdb.generated.conf

_Note: You can then use the `-config` parameter to launch InfluxDB.  For example, `influxd -config influxdb.conf`_

**Configure InfluxDB for Automatic start-up**

    systemctl enable influxdb.service

**Start InfluxDB**

    sudo service influxdb start

**The InfluxDB Web Interface**

Once InfluxDB is up and running, connect to it using a web browser.

    http://<ip address>:8083

**Using the `influx` CLI**

To interact with your installation of InfluxDB (i.e. create users, databases, etc.) perform the following:

1\.  SSH to your InfluxDB VM 

2\.  Change directory to `/usr/bin`

3\.  Type `influx` and hit enter

	[ibmcloud@rscase2 ~]$ influx
	Visit https://enterprise.influxdata.com to register for updates, InfluxDB server management, and monitoring.
	Connected to http://localhost:8086 version 1.0.0
	InfluxDB shell version: 1.0.0
	>

<!---
**Create InfluxDB User(s)**

For this example, create a user called `esx` with a password of `esx`.  Type the following into your influx CLI session and press enter.

    CREATE USER esx WITH PASSWORD 'esx' WITH ALL PRIVILEGES

_Tip: Influx commands only return interactive messages on failure.  So after hitting enter above, if you get no feedback, this is good._

_For full details on Influx authentication:
[https://docs.influxdata.com/influxdb/v0.11/administration/authentication_and_authorization/](https://docs.influxdata.com/influxdb/v0.11/administration/authentication_and_authorization/)_
-->
	
**Create InfluxDB Database**

Create a database called `service_status`.

    CREATE DATABASE service_status

_Note: We will use this database in the next steps._