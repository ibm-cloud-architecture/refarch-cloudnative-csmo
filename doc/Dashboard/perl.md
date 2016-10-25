#Prepare perl runtime
Perl script [`grafana_collect.pl`](scripts/grafana_collect.pl) is an important part of dashboarding solution for BlueCompute.
It collects data from the following data sources:

- Bluemix Clound Foundry API
- Bluemix Container API
- New Relic API
- NOI (Omnibus ObjectServer) API
- pseudo-CMDB
- BAM (planned)

and store in the InfluxDB which is a primary data source for Grafana dashboard.
Script is based on [Mojolicious](http://mojolicious.org) perl web framework and can be deployed on any operating system supported by perl and prerequisite perl modules and in Bluemix as a Cloud Foundry application. This document specify steps needed to deploy it and run on Centos 7 VM.    

Use the following steps to install prerequisite system packages and perl modules required for data collection script.

**Install Centos packages**

	sudo yum install perl-devel perl-CPAN gcc

**Install prerequisite perl modules**

There are meny methods of installing perl modules - we used `cpanm`.

Install `cpanm` _*require internet connection_. Using command:
```sh
sudo curl -L http://cpanmin.us | perl - --sudo App::cpanminus
```

Before installing perl modules, make sure that MySQL server or client is installed on the system. 
In our environment, MySQL server with `cmdb` database was installed on the same Centos 7 VM as other dashboarding solution components: Grafana, InfluxDB and grafana_collect.pl.
Install the following perl modules using `cpanm` (_require internet connection_)::

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

Copy [`grafana_collect.pl`](scripts/grafana_collect.pl) to the server (_I used /case directory_) and make it executable.
List routes defined by the script to check if it starts correctly:

	./grafana.pl routes

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

**Configure perl script to start with the system**

Centos 7 uses `systemd` to initialize operating system components that must be started after Linux kernel is booted. Configure `systemd` to start grafana_collect.pl as a daemon together with the Operating System.

1. Copy service definition [grafana_collect.service](scripts/grafana_collect.service) to /etc/systemd/system directory. Note that provided service definition assumes that perl script is located in `/case` directory. Edit `grafana_collect.service` if you want to change script location or listening port (it uses port 3001 by default).

2. Enable new service to start with the system.

	systemctl enable grafana_collect

3. Start the `grafana_collect` service.

	systemctl start grafana_collect

4. Verify that the script started correctly.

	systemctl status grafana_collect

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

**Schedule periodic API calls**

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
