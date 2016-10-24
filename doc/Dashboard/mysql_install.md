# Installing MySQL on Centos 7
MySQL is a popular database management system used for web and server applications. CSMO solution use MySQL as CMDB database storing configuration information for CSMO solution components. Use the steps below to install MySQL on Centos 7.


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
