
- [Monitoring Dashboard for BlueCompute](#monitoring-dashboard-for-bluecompute)
- [Grafana](#grafana)
	- [Installing Grafana on Centos 7](#installing-grafana-on-centos-7)
	- [Grafana configuration](#grafana-configuration)
- [InfluxDB](#influxdb)
	- [Requirements](#requirements)
	- [Installing InfluxDB on Centos 7](#installing-influxdb-on-centos-7)
	- [Configure InfluxDB](#configure-influxdb)
- [MySQL](#mysql)
	- [Installing MySQL on Centos 7](#installing-mysql-on-centos-7)
	- [Create a CMDB User and Database](#create-a-cmdb-user-and-database)
	- [Create CMDB database schema and import example](#create-cmdb-database-schema-and-import-example)
- [PHP](#php)
	- [CMDB UI configuration](#cmdb-ui-configuration)
- [Data collection for Dashboard - grafana_collect.pl](#data-collection-for-dashboard-grafanacollectpl)
	- [Install prerequisite Centos packages](#install-prerequisite-centos-packages)
	- [Install prerequisite perl modules](#install-prerequisite-perl-modules)
	- [Complete script configuration](#complete-script-configuration)
	- [Configure perl script to start with the system](#configure-perl-script-to-start-with-the-system)
	- [Schedule periodic API calls](#schedule-periodic-api-calls)
- [Dashboard configuration](#dashboard-configuration)
	- [Configuring data sources](#configuring-data-sources)
		- [InfluxDB](#influxdb)
		- [New Relic APM](#new-relic-apm)
	- [Import dashboards](#import-dashboards)
- [CSMO dashboard for BlueCompute](#csmo-dashboard-for-bluecompute)
	- [First Responder dashboard](#first-responder-dashboard)
	- [BlueCompute application details dashboard](#first-responder---bluecompute-application-details-dashboard)

# Monitoring Dashboard for BlueCompute
Author: Rafał Szypułka (rafal.szypulka@pl.ibm.com)

Monitoring Dashboard is an entry point UI for First Responder persona who will react on alerts from Incident Management.
It gives an overall view on current status of all BlueCompute Hybrid application components. It allows also to contextually drill down to more detailed information about topology, performance metrics, log files and generated alerts.
This document will describe, how to deploy whole dashboarding solution on single Centos 7 server.

Diagram below explains the data flow for the dashboard.
[Data collection component](#data-collection-for-dashboard-grafanacollectpl) collects data from the following data sources:

- Bluemix Clound Foundry API
- Bluemix Container API
- New Relic API
- NOI (Omnibus ObjectServer) API
- CMDB database
- BAM (planned)

Collected data is stored in [InfluxDB](#influxdb) timeseries database, which is the primary data source for [Grafana](#grafana) dashboarding engine.

![Flowchart](images/BlueCompute_dashboard_flowchart1.png)

# Grafana
[Grafana](http://grafana.org) is one of the leading tools for querying and visualizing time series and metrics. In the CSMO project we used it to create dashboards for First Responder persona.
Grafana features a variety of panels, including fully featured graph panels with rich visualization options. There is built in support for many of the time series data sources like InfluxDB or Graphite. We used InfluxDB - a time series database for metrics as a data source for Grafana and perl script to collect data from various APIs of BlueCompute CSMO infrastructure like New Relic, Bluemix, NOI or CMDB.

## Installing Grafana on Centos 7

**Download**

Description | Download
------------ | -------------
Stable .RPM for CentOS | [3.1.1 (x86-64 rpm)](https://grafanarel.s3.amazonaws.com/builds/grafana-3.1.1-1470047149.x86_64.rpm)

**Installation**

You can install Grafana using Yum directly.

    $ sudo yum install https://grafanarel.s3.amazonaws.com/builds/grafana-3.1.1-1470047149.x86_64.rpm

**Package details**

- Installs binary to `/usr/sbin/grafana-server`
- Copies init.d script to `/etc/init.d/grafana-server`
- Installs default file (environment vars) to `/etc/sysconfig/grafana-server`
- Copies configuration file to `/etc/grafana/grafana.ini`
- Installs systemd service (if systemd is available) name `grafana-server.service`
- The default configuration uses a log file at `/var/log/grafana/grafana.log`
- The default configuration specifies an sqlite3 database at `/var/lib/grafana/grafana.db`


## Grafana configuration
**Start the server (via systemd)**

    $ sudo systemctl daemon-reload
    $ sudo systemctl start grafana-server
    $ sudo systemctl status grafana-server

**Enable the systemd service to start at boot**

    sudo systemctl enable grafana-server.service

**Environment file**

The systemd service file and init.d script both use the file located at
`/etc/sysconfig/grafana-server` for environment variables used when
starting the back-end. Here you can override log directory, data
directory and other variables.

**Logging**

By default Grafana will log to `/var/log/grafana`.

**Database**

The default configuration specifies a sqlite3 database located at
`/var/lib/grafana/grafana.db`. Please backup this database before
upgrades.

**Grafana configuration file**

The configuration file is located at `/etc/grafana/grafana.ini`.  Go the
[Configuration](http://docs.grafana.org/installation/configuration) page for details on all
those options.


#InfluxDB
[InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/) is an open-source time series database developed by InfluxData as part of their time series platform. It is written in Go and optimized for fast, high-availability storage and retrieval of time series data in fields such as operations monitoring, application metrics, Internet of Things sensor data, and real-time analytics. Here InfluxDB is used as storage for metrics collected by perl runtime and primary data source for Grafana dashboard.

## Requirements

Installation of the InfluxDB package may require `root` privileges in order to complete successfully.

**Networking**

By default, InfluxDB uses the following network ports:

- TCP port `8083` is used for InfluxDB's Admin panel
- TCP port `8086` is used for client-server communication over InfluxDB's HTTP API

In addition to the ports above, InfluxDB also offers multiple plugins that may
require custom ports.
All port mappings can be modified through the [configuration file](docs.influxdata.com/influxdb/v1.0/administration/config),
which is located at `/etc/influxdb/influxdb.conf` for default installations.

## Installing InfluxDB on Centos 7

RedHat and CentOS users can install the latest stable version of InfluxDB using the `yum` package manager:

```bash
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.0.0.x86_64.rpm
sudo yum localinstall influxdb-1.0.0.x86_64.rpm
sudo systemctl start influxdb
sudo systemctl status influxdb
```

##Configure InfluxDB

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

# MySQL

MySQL is a popular database management system used for web and server applications. CSMO solution for BlueCompute use MySQL as CMDB database, storing configuration information for CSMO solution components. Use the steps below to install MySQL on Centos 7.

## Installing MySQL on Centos 7

	sudo yum update
	yum install mysql-server
	systemctl start mysqld

After installation, run interactive configuration program and specify configuration settings according to prompts.

	sudo mysql_secure_installation

You will be given the choice to change the MySQL root password, remove anonymous user accounts, disable root logins outside of localhost, and remove test databases. It is recommended that you answer yes to these options. You can read more about the script in the MySQL Reference Manual.

The standard tool for interacting with MySQL is the mysql client which installs with the mysql-server package. The MySQL client is used through a terminal.

Log in to MySQL as the root user:


	mysql -u root -p

When prompted, enter the root password you assigned when the mysql_secure_installation script was run.
You’ll then be presented with a welcome header and the MySQL prompt as shown below:

	mysql>

##Create a CMDB User and Database
In the example below, `cmdb` is the name of the database, `cmdb` is the user, and `cmdb` is the user’s password.

```sql
create database cmdb;
create user 'cmdb'@'localhost' identified by 'cmdb';
grant all on cmdb.* to 'cmdb' identified by 'cmdb';
```


##Create CMDB database schema and import example
Use provided sql [script](scripts/cmdb.sql) to create table and import example data.

	mysql -u cmdb -p cmdb < cmdb.sql

When prompted, enter the `cmdb` user password you assigned when the `cmdb` user was created.

# PHP

PHP is an open source web scripting language that is widely used to build dynamic webpages. We will need it for UI that will allow to view, create, update and delete records in the MySQL CMDB database.

>Before php installation make sure that httpd and mysql-server packages are installed.

To install PHP on dashboard server, open terminal and type in this command:

	sudo yum install php php-mysql

Once you answer yes to the PHP prompt, PHP will be installed.

## CMDB UI configuration

1. Download latest release of the prerequisite php application [phpMyEdit](http://opensource.platon.org/projects/release_list_page.php?project_id=5).
2. Extract it in httpd server root directory (/var/www/html by default on Centos 7), so the following path should be visible: `/var/www/html/phpmyedit/phpMyEdit.class.php` (rename directories if needed).
3. Copy script [cmdb.php](scripts/cmdb.php) to httpd (Apache Http Server) root directory (/var/www/html).
4. Verify that you can access CMDB URL:
`http://<dashboard_server_ip>/cmdb.php`

![cmdb_ui](images/cmdb_ui1.png)

#Data collection for Dashboard - grafana_collect.pl

Perl script [`grafana_collect.pl`](scripts/grafana_collect.pl) is a data collection component of dashboarding solution for BlueCompute.
It collects data from the following data sources:

- Bluemix Clound Foundry API
- Bluemix Container API
- New Relic API
- NOI (Omnibus ObjectServer) API
- pseudo-CMDB
- BAM (planned)

and stores in the InfluxDB which is a primary data source for Grafana dashboard.
Script is based on [Mojolicious](http://mojolicious.org) perl web framework and can be deployed on any operating system supported by perl and prerequisite perl modules and in Bluemix as a Cloud Foundry application. This document specify steps needed to deploy it and run on Centos 7 VM.    

Use the following steps to install prerequisite system packages and perl modules required for data collection script.

##Install prerequisite Centos packages

	sudo yum install perl-devel perl-CPAN gcc

##Install prerequisite perl modules

There are meny methods of installing perl modules - one of them is `cpanm`.

Install `cpanm` using command (_require internet connection_):

```sh
sudo curl -L http://cpanmin.us | perl - --sudo App::cpanminus
```

Before installing perl modules, make sure that MySQL server or client is installed on the system.
In our environment, MySQL server with `cmdb` database was installed on the same Centos 7 VM as other dashboarding solution components: Grafana, InfluxDB and [`grafana_collect.pl`](scripts/grafana_collect.pl).
Install the following perl modules using `cpanm` (_require internet connection_):

- Mojolicious::Lite
- Data::Dumper
- JSON
- Text::ASCIITable
- InfluxDB::LineProtocol
- Hijk
- HTML::Table
- DBD::MySQL

```
cpanm Mojolicious::Lite Data::Dumper JSON Text::ASCIITable InfluxDB::LineProtocol Hijk HTML::Table DBD::MySQL
```
##Complete script configuration
Copy [`grafana_collect.pl`](scripts/grafana_collect.pl) to the server (_I used /case directory_) and make it executable.
List routes defined by the script to check if it starts correctly:

	./grafana_collect.pl routes

The output should be similar to the following:


	[root@rscase case]# ./grafana_collect.pl routes
	/nr_cmdb           GET  nr_cmdb
	/nr_mysql_cmdb     GET  nr_mysql_cmdb
	/nr_nginx_cmdb     GET  nr_nginx_cmdb
	/logmet_redirect   GET  logmet_redirect
	/container_status  GET  container_status
	/bmx_app_status    GET  bmx_app_status
	/noi_app_severity  GET  noi_app_severity
	/list              GET  list
	/html              GET  html
	/query             *    query
	/search            *    search

Edit the script [`grafana_collect.pl`](scripts/grafana_collect.pl) and change the following variables according to comments inside the script:

```perl
############### Edit section below ###############################################################
my $api_key       = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'; # New relic API Key
my $bmx_space_guid =
  'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';               # cf space cloudnative-dev --guid

my $noi_user     = "xxxx";                                 # Omnibus user
my $noi_password = "xxxxxxxxx";                            # Ominbus user password
my $noi_api =
  "http://${noi_user}:${noi_password}\@xxx.xxx.xxx.xxx:8080/objectserver/restapi/sql/factory/";
                                                           # insert Netcool Omnibus IP address above
my $bmx_username = 'xxxxxxxxxxxxxxxx';                     # Bluemix user id
my $bmx_password = 'xxxxxxxx';                             # Bluemix user password
my $influx_host  = 'localhost';                            # change is InfluxDB is installed remotely
my $influx_port  = '8086';                                 # change is Inlfux DB port is non-default
my $uid = "cmdb";                                          # MySQL user for CMDB database
my $pwd = 'cmdb';                                          # MySQL user password
##########################################################################################
```

Start the script. It will automatically start buil-in web server.

	./grafana_collect.pl daemon -l http://*:3002

In the separate shell session on the same server execute:

	curl http://localhost:3002/list

If the script is configured correctly (proper credentials, proper API keys, CMDB properly set up, etc.), you should see the similar output:

	[root@rscase case]# curl localhost:3002/list
	.------------------------------------------------------------------------------------------------------------------------------------------.
	|                                                         New Relic Service Status                                                         |
	+-----------------------------------+----------+--------------+----------------+----------+----------+--------+---------------+------------+
	| Name                              | Id       | Region Name  | Service Name   | Client   | Language | Status | Response time | Error rate |
	+-----------------------------------+----------+--------------+----------------+----------+----------+--------+---------------+------------+
	| inventory-bff-app-dev             | 31935607 | bmx_eu-gb    | BlueCompute    | CASE-DEV | nodejs   | green  | -             | -          |
	| bluecompute-web-app               | 31939678 | bmx_eu-gb    | BlueCompute    | CASE-DEV | nodejs   | green  |          15.8 | -          |
	| socialreview-bff-app              | 32528997 | bmx_eu-gb    | BlueCompute    | CASE-DEV | nodejs   | green  |            64 | -          |
	'-----------------------------------+----------+--------------+----------------+----------+----------+--------+---------------+------------'

Stop the script using `CTRL-c`.

##Configure perl script to start with the system

Centos 7 uses `systemd` to initialize operating system components that must be started after Linux kernel is booted. Configure `systemd` to start grafana_collect.pl as a daemon together with the Operating System.

1. Copy service definition [grafana_collect.service](scripts/grafana_collect.service) to /etc/systemd/system directory. Note that provided service definition assumes that perl script is located in `/case` directory. Edit `grafana_collect.service` if you want to change script location or listening port (it uses port 3001 by default).

2. Enable new service to start with the system.

```
systemctl enable grafana_collect
```

3. Start the `grafana_collect` service.

```
	systemctl start grafana_collect
```

4. Verify that the script started correctly.

```
	systemctl status grafana_collect
```

Expected output:

```
	[root@rscase ~]# systemctl status grafana_nr
	● grafana_nr.service - CASE project app for Grafana
	   Loaded: loaded (/etc/systemd/system/grafana_nr.service; enabled; vendor preset: disabled)
	   Active: active (running) since Fri 2016-10-21 07:50:37 CDT; 21h ago
	 Main PID: 1115 (grafana_nr.sh)
	   CGroup: /system.slice/grafana_nr.service
	           ├─ 1115 /bin/sh /case/grafana_nr.sh
	           ├─ 1207 perl /case/1grafana_nr.pl prefork -m production -l http://*:3001
	           ├─ 1210 perl /case/1grafana_nr.pl prefork -m production -l http://*:3001
	           ├─15076 perl /case/1grafana_nr.pl prefork -m production -l http://*:3001
	           ├─15277 perl /case/1grafana_nr.pl prefork -m production -l http://*:3001
	           └─15347 perl /case/1grafana_nr.pl prefork -m production -l http://*:3001
```

	curl http://localhost:3001/list

Expected output:

	[root@rscase case]# curl localhost:3001/list
	.------------------------------------------------------------------------------------------------------------------------------------------.
	|                                                         New Relic Service Status                                                         |
	+-----------------------------------+----------+--------------+----------------+----------+----------+--------+---------------+------------+
	| Name                              | Id       | Region Name  | Service Name   | Client   | Language | Status | Response time | Error rate |
	+-----------------------------------+----------+--------------+----------------+----------+----------+--------+---------------+------------+
	| inventory-bff-app-dev             | 31935607 | bmx_eu-gb    | BlueCompute    | CASE-DEV | nodejs   | green  | -             | -          |
	| bluecompute-web-app               | 31939678 | bmx_eu-gb    | BlueCompute    | CASE-DEV | nodejs   | green  |          15.8 | -          |
	| socialreview-bff-app              | 32528997 | bmx_eu-gb    | BlueCompute    | CASE-DEV | nodejs   | green  |            64 | -          |
	'-----------------------------------+----------+--------------+----------------+----------+----------+--------+---------------+------------'

##Schedule periodic API calls

API calls done by [`grafana_collect.pl`](scripts/grafana_collect.pl) are activated by external HTTP GET requests to perl runtime web server, listening on port `3001` by default. One of the ways to schedule periodic API calls is to create short shell script that will do the HTTP GET requests and schedule it by cron.
Below are the configuration steps:

1. Copy the [grafana_collect_run.sh](scripts/grafana_collect_run.sh) to the server (_I copied it to my home drectory_) and make it executable.
2. Configure `cron` to run it every 1 minute using `crontab -e` as non-root user.

First batch of data should be available in InfluxDB after about 1 minute.
Enter InfluxDB shell or web console http://localhost:8083 and verify that data was written to database:

```
[root@rscase rafal]# influx
Visit https://enterprise.influxdata.com to register for updates, InfluxDB server management, and monitoring.
Connected to http://localhost:8086 version 1.0.0
InfluxDB shell version: 1.0.0
> use service_status
Using database service_status
> show measurements
name: measurements
------------------
name
bmx_app_status
container_status
mysql_status
ngnix_status
noi_app_severity
service_status

> select * from bmx_app_status limit 3
name: bmx_app_status
--------------------
time			 	cf_name					instances	running_instances	status	status_num
1477134025269798000	bluecompute-web-app		1			1					STARTED	0
1477134025269876000	inventory-bff-app-dev	1			1					STARTED	0
1477134025269942000	socialreview-bff-app	1			1					STARTED	0

> select * from noi_app_severity limit 3
name: noi_app_severity
----------------------
time				app_name							highest_sev
1477134023670451000	micro-socialreview-cloudnative-qa	0
1477134023670493000	eureka-cluster-eu					5
1477134023670522000	Python Application					0

> exit
```
# Dashboard configuration
After our data collection layer is up and runnig and data is coming to InfluxDB, we can start with Grafana dashboard configuration.

## Configuring data sources

###InfluxDB

InfluxDB Primary is the primary data source for the BlueCompute dashboard. It is installed by default in Grafana.

**Configuration**

Open the URL: `http://\<grafana_hostname>:3000/datasources` in the browser and enter the name of the data source, InfluxDB URL and database name. Select InfluxDB as Data Source type.

![influxdb_datasource](images/influxdb_datasource.png)

Click Save & Test.

###New Relic APM

Detailed dashboards for BlueCompute components monitored by New Relic are rendered based on New Relic Data Source.

**Installation**

Download New Relic Data Source code from [GitHub project page](https://github.com/wevanscfi/grafana-newrelic-apm-datasource), and copy to the following subdirectory on Grafana server: `/var/lib/grafana/plugins/newrelic`

**Configuration**

Open the `URL: http://\<grafana_hostname>:3000/datasources` and enter the name of the data source (use the same name as the application name), New Relic API Key and application id. Select NewRelic as Data Source type.

![newrelic_datasource](images/newrelic_datasource.png)

>Repeat it for every application monitored by New Relic.

## Import dashboards
The following dashboards were developed by CSMO for BlueCompute:

- [1 - BlueCompute Application Summary - First Responder](scripts/1 - BlueCompute Application Summary - First Responder.json)
- [2 - BlueCompute Application Details](scripts/2 - BlueCompute Application Details.json)

Click on the links above or clone this git repository to access dashboard definition json files.
Dashboad json files can be imported using Grafana UI: click on the top-left menu and select Dashboards -> Import.

![grafana_import](images/grafana_import.png)

# CSMO dashboard for BlueCompute

##First Responder dashboard
First responder dashboard URL:

`http://<dashboard_server_ip>:3000/dashboard/db/1-bluecompute-application-summary-first-responder`

Dashboard is divided into the following sections:
- Key metrics (work in progress) for BlueCompute Hybrid Application.
- Bluemix Cloud Foundry Applications
- Bluemix Container Applications
- Bluemix Containers
- Nginx Load Balancer
- IBM SoftLayer Databases

**Grafana panels:**

- Bluemix Cloud Foundry Applications and Bluemix Container Applications

|Panel   |Description   |Source   |
|---|---|---|
|Region   |Location of the application   | CMDB   |
|Language   |Programming language of the application   |New Relic API   |
|NR Status   |Application status in New Relic   |New Relic API   |
|NOI Severity   |Highest severity for NOI alert for specific application   |Omnibus ObjectServer API   |
|BMX status   |Status of the CF application in Bluemix   |Bluemix Cloud Foundry API   |
|BMX Instances   |Number of CF Application instances   |Bluemix Cloud Foundry API   |
|Response Time <br/>Error Rate<br/>APDEX score<br/>APDEX target|Key application metrics |New Relic API
- Bluemix Containers

|Panel   |Description   |Source   |
|---|---|---|
|Region   |Location of the application   | CMDB   |
|BMX status   |Status of the IBM Container in Bluemix   |Bluemix IBM Container API   |
|NOI Status   |Highest severity for NOI alert for specific container   |Omnibus ObjectServer API   |
|IC Type   |IBM Container type: single container or container group   |Bluemix IBM container API   |
|Instances  |Highest severity for NOI alert for specific application   |Bluemix IBM container API   |
|IC instances status   |Number of CF Application instances   |Bluemix IBM container API   |

- Nginx Load Balancer

|Panel   |Description   |Source   |
|---|---|---|
|Region   |Location of the Nginx Load Balancer   | CMDB   |
|NOI Status   |Highest severity for NOI alert for Load Balancer   |Omnibus ObjectServer API   |
|Active Connections  |Number of active connections to Load Balancer   |New Relic API   |
|Total Request Rate  |Request rate per second   |New Relic API   |
|Connection Drop Rate   |Connection Drop Rate per second   |New Relic API   |

- IBM SolftLayer Databases

|Panel   |Description   |Source   |
|---|---|---|
|Region   |Location of the MySQL Database   | CMDB   |
|NOI Status   |Highest severity for NOI alert for MySQL   |Omnibus ObjectServer API   |
|Reads/s  |MySQL Reads per second   |New Relic API   |
|Writes/s  |MySQL Writes per second  |New Relic API   |
|Connections   |MySQL number of connections  |New Relic API   |

**Drill down entry points**

First Responder Dashboard includes several context entry point to more detailed information about specific solution components:

1. Link to Bluemix Logmet service. It opens Logmet Kibana4 dashboard with all log records from BlueCompute collected by Logmet service.
2. Link to New Relic Service Map for BlueCompute. It shows topology diagram for BlueCompute components monitored by New Relic.
3. Click on the "NR Status" panel moves to New Relic console with list of monitored applications and more detailed information about application performance.
4. Click on the "NOI Severity" panel moves to NOI Event Viewer console with the list of alerts generated for this application.
5. Link to more detailed Grafana dashboard "BlueCompute Application Details" for specific application only.
6. Link to Bluemix Logmet service. It opens Logmet Kibana4 dashboard with log records from specific application only.
7. Link to more detailed Grafana dashboard "BlueCompute Application Details" for specific application only.
8. Link to Logmet Grafana dashboard with metrics like CPU and Memory for specific container or container group.
9. 10. Links to New Relic console with list of monitored applications and more detailed information about monitored components.


![img](images/Grafana_first_responder_big_desc1.png)

##BlueCompute application details dashboard

BlueCompute application details dashboard shows detailed graphs for BleuCompute components monitored. All metrics in this dashboard are collected using [New Relic Data Source](#new-relic-apm) that collects data directly from New Relic API.

 - Web Transactions Total Time
 - Average Response Time per minute for HttpDispatcher and WebFrontend/QueueTime
 - Memory Used by the monitored application
 - Error Rate
 - Response Time for HttpDispatcher compared to Request volume
 - Response Time for WebFrontend/QueueTime compared to Request volume


![img](images/Grafana_first_responder_detail_big.png)
