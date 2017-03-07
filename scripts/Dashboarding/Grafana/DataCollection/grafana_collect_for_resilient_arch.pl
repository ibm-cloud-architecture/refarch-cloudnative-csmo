#!/usr/bin/env perl
use Mojolicious::Lite;
use Data::Dumper;
use JSON;
use Text::ASCIITable;
use InfluxDB::LineProtocol qw(data2line line2data);
use Hijk;
use HTML::Table;
use DBI;
use Config::Simple;

my $debug = 'test';

### New Relic settings ###
my $newrelic_url        = 'https://api.newrelic.com/v2/applications.json';
my $newrelic_components = 'https://api.newrelic.com/v2/components.json';
my $newrelic_servers    = 'https://api.newrelic.com/v2/servers.json';
my $api_key             = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

### Bluemix settings ###
my $bluemix_auth        = 'https://login.ng.bluemix.net/UAALoginServerWAR/oauth/token';
my $bmx_containers_api_us  = 'https://containers-api.ng.bluemix.net/v3/containers/json';
my $bmx_containers_api_eugb = 'https://containers-api.eu-gb.bluemix.net/v3/containers/json';
my $bmx_container_group = 'https://containers-api.ng.bluemix.net/v3/containers/groups';
#cf space cloudnative-prod --guid (executed on ng)
my $bmx_space_guid_us_prod    = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; 	
my $bmx_space_guid_eugb_prod  = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
my $bmx_space_guid_us_integ   = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; 	
my $bmx_space_guid_eugb_integ = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
my $bmx_space_guid_eugb_qa    = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
my $bmx_space_guid_us_qa      = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
my $bmx_apps_api_us_prod      = "https://api.ng.bluemix.net/v2/spaces/${bmx_space_guid_us_prod}/summary";
my $bmx_apps_api_eugb_prod    = "https://api.eu-gb.bluemix.net/v2/spaces/${bmx_space_guid_eugb_prod}/summary";
my $bmx_apps_api_us_integ     = "https://api.ng.bluemix.net/v2/spaces/${bmx_space_guid_us_integ}/summary";
my $bmx_apps_api_eugb_integ   = "https://api.eu-gb.bluemix.net/v2/spaces/${bmx_space_guid_eugb_integ}/summary";
my $bmx_apps_api_us_qa        = "https://api.ng.bluemix.net/v2/spaces/${bmx_space_guid_us_qa}/summary";
my $bmx_apps_api_eugb_qa      = "https://api.eu-gb.bluemix.net/v2/spaces/${bmx_space_guid_eugb_qa}/summary";
my $bmx_username              = 'xxxxxxxxxxxxxxxx';
my $bmx_password              = 'xxxxxxxxxx';

### NOI settings ###
my $noi_user     = "xxxxx";
my $noi_password = "xxxxxxxxx";
my $noi_server   = "xxxxxxxxxxx";
my $noi_api      = "http://${noi_user}:${noi_password}\@${noi_server}:8080/objectserver/restapi/sql/factory/";
my $noi_sql      = 'select Serial, Node, Service, to_char(LastOccurrence), Severity from alerts.status where SuppressEscl < 4';
#'select Serial, Node, Service, to_char(LastOccurrence), Severity from alerts.status where Severity >= 5';
#'select Serial, Node, Service, to_char(LastOccurrence), Severity from alerts.status';

### Logmet settings ###
my $logmet_dash_search  = 'https://logmet.eu-gb.bluemix.net/elasticsearch/grafana-dash/dashboard/_search';
my $logmet_sql          = "select LOGMET_GRAFANA_ID from cmdb";

### InfluxDB settings ###
my $influx_host  = 'localhost';
my $influx_port  = '8086';

### MySQL CMDB settings ###
my $dsn          = "DBI:mysql:database=cmdb;host=localhost";
my $uid          = "cmdb";
my $pwd          = 'cmdb';
my $cmdb_sql     = "select APPNAME,APPTYPE,APPID,REGIONNAME,ENVNAME,CLIENT,DESCRIPTION,SERVICENAME,SERVICEID from cmdb";
#"select APPNAME,APPID,REGIONNAME,CLIENT,DESCRIPTION,SERVICENAME,SERVICEID from BMXCMDB_SERVICEMAP";


sub send_to_influx {
    my $line = shift;
    open( F, ">>influx.log" );
    my $res = Hijk::request(
        {
            method       => 'POST',
            host         => $influx_host,
            port         => $influx_port,
            path         => "/write",
            query_string => "db=service_status",
            body         => $line
        }
    );
    print F scalar(localtime) . " POST to influx $res->{status}\n";
    if ( $res->{status} != 204 ) {
        print F scalar(localtime) . " POST to influx line: $line\n";
        sleep 1;
        my $res = Hijk::request(
            {
                method       => 'POST',
                host         => $influx_host,
                port         => $influx_port,
                path         => "/write",
                query_string => "db=sevice_status",
                body         => $line
            }
        );
        print F scalar(localtime) . " RETRY!!!! POST to influx $res->{status}\n";
        print F scalar(localtime) . " POST to influx line: $line\n";
    }
    close F;
}


get '/json' => sub {
    my $c = shift;
    my $headers = { Accept => 'application/json' };

    # $c->ua->get( $newrelic_url => { 'X-Api-Key' => $api_key } )->res->body;
    my $app_json = $c->ua->post(
        $noi_api => {
            'Accept'       => 'application/json',
            'Content-Type' => 'application/json',
            charset        => 'UTF-8'
          } => json => {
            sqlcmd => $noi_sql
          } => sub {
            my ( $ua, $tx ) = @_;
            #say Dumper $tx;
        }
    )->res->body;
    $c->render( json => $app_json );
};

#sends request to New Relic API, parses JSON output, formats InfluxDB LineProtocol lines and writes to InfluxDB
get '/nr_cmdb' => sub {
    my $c = shift;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );

    $c->ua->get(
        $newrelic_url => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;
            for my $row (@$data_ref) {
                foreach my $i ( @{ $tx->res->json->{applications} } ) {
                    if ( $row->{APPNAME} eq $i->{name} ) {
                        my $error_rate =
                          $i->{application_summary}->{error_rate} // 0.0;
                        $error_rate .= '.0' if ( $error_rate =~ /^\d+$/ );
                        my $response_time =
                          $i->{application_summary}->{response_time} // 0.0;
                        $response_time .= '.0' if ( $response_time =~ /^\d+$/ );
                        my $throughput =
                          $i->{application_summary}->{throughput} // 0.0;
                        $throughput .= '.0' if ( $throughput =~ /^\d+$/ );
                        my $apdex_target =
                          $i->{application_summary}->{apdex_target} // 0.0;
                        $apdex_target .= '.0' if ( $apdex_target =~ /^\d+$/ );
                        my $apdex_score =
                          $i->{application_summary}->{apdex_score} // 0.0;
                        $apdex_score .= '.0' if ( $apdex_score =~ /^\d+$/ );
                        my $host_count =
                          $i->{application_summary}->{host_count} // 0.0;
                        $host_count .= '.0' if ( $host_count =~ /^\d+$/ );
                        my $instance_count =
                          $i->{application_summary}->{instance_count} // 0.0;
                        $instance_count .= '.0'
                          if ( $instance_count =~ /^\d+$/ );
                        my $language = $i->{language};
                        my $status = $i->{health_status} // '';
                        $status = 0 if $status eq 'green';
                        $status = 1 if $status eq 'yellow';
                        $status = 2 if $status eq 'red';
                        $status = 3 if $status eq 'gray';
                        my (
                            $description, $regionname, $servicename,
                            $serviceid,   $client,  $apptype, $envname
                        );

                        $description = $row->{DESCRIPTION};
                        $regionname  = $row->{REGIONNAME};
                        $servicename = $row->{SERVICENAME};
                        $serviceid   = $row->{SERVICID};
                        $client      = $row->{CLIENT};
						$apptype	 = $row->{APPTYPE};
						$envname     = $row->{ENVNAME};
						

                        $line .= data2line(
                            'service_status',
                            {
                                status         => ${status},
                                error_rate     => ${error_rate},
                                response_time  => ${response_time},
                                throughput     => ${throughput},
                                apdex_target   => ${apdex_target},
                                apdex_score    => ${apdex_score},
                                host_count     => ${host_count},
                                instance_count => ${instance_count}
                            },
                            {
                                name        => $i->{name},
                                language    => ${language},
                                regionname  => $regionname,
                                servicename => $servicename,
                                client      => $client,
								apptype		=> $apptype,
								envname     => $envname
                            }
                        );

                        $line .= "\n";
                    }
                }
            }
            chomp $line;
            #say $line;
            send_to_influx($line);
        }
    );

    $c->render( text => 'ok' );
};

get '/nr_mysql_cmdb' => sub {
    my $c        = shift;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
	my $cmdb_sql_mysql = $cmdb_sql . qq| WHERE APPTYPE = 'mysql'|; 
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql_mysql, { Slice => {} } );

    $c->ua->get(
        $newrelic_components => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;
			
            for my $row (@$data_ref) {
				#say $row->{APPNAME};
                foreach my $i ( @{ $tx->res->json->{components} } ) {
					
                    if ( $row->{APPNAME} eq $i->{name} ) {
						
                        my $reads = $i->{summary_metrics}[0]->{values}->{raw};
                        $reads .= '.0' if ( $reads =~ /^\d+$/ );
                        my $writes = $i->{summary_metrics}[1]->{values}->{raw};
                        $writes .= '.0' if ( $writes =~ /^\d+$/ );
                        my $connections =
                          $i->{summary_metrics}[2]->{values}->{raw};
                        $connections .= '.0' if ( $connections =~ /^\d+$/ );
                        my $description = $row->{DESCRIPTION};
                        my $regionname  = $row->{REGIONNAME};
						my $envname  = $row->{ENVNAME};
                        my $servicename = $row->{SERVICENAME};
                        my $serviceid   = $row->{SERVICID};
                        my $client      = $row->{CLIENT};

                        $line .= data2line(
                            'mysql_status',
                            {
                                reads       => ${reads},
                                writes      => ${writes},
                                connections => ${connections},
                            },
                            {
                                name        => $i->{name},
                                regionname  => $regionname,
								envname  => $envname,
                                servicename => $servicename,
                                client      => $client
                            }
                        );
                    }
                }
                $line .= "\n";
            }
            chomp $line;
            #say $line;
            send_to_influx($line);
        }

    );
    $c->render( text => 'ok' );
};

get '/nr_servers_cmdb' => sub {
    my $c        = shift;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
	my $cmdb_sql_servers = $cmdb_sql . qq| WHERE APPTYPE = 'vm'|; 
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql_servers, { Slice => {} } );

    $c->ua->get(
        $newrelic_servers => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;
			
            for my $row (@$data_ref) {
				#say $row->{APPNAME};
                foreach my $i ( @{ $tx->res->json->{servers} } ) {
					#say $i->{name};
                    if ( $row->{APPNAME} eq $i->{name} ) {
						
                        my $cpu =
                          $i->{summary}->{cpu} // 0.0;
                        $cpu .= '.0' if ( $cpu =~ /^\d+$/ );
                        my $cpu_stolen =
                          $i->{summary}->{cpu_stolen} // 0.0;
                        $cpu_stolen .= '.0' if ( $cpu_stolen =~ /^\d+$/ );
                        my $disk_io =
                          $i->{summary}->{disk_io} // 0.0;
                        $disk_io .= '.0' if ( $disk_io =~ /^\d+$/ );
                        my $memory =
                          $i->{summary}->{memory} // 0.0;
                        $memory .= '.0' if ( $memory =~ /^\d+$/ );
                        my $memory_used =
                          $i->{summary}->{memory_used} // 0.0;
                        $memory_used .= '.0' if ( $memory_used =~ /^\d+$/ );
                        my $memory_total =
                          $i->{summary}->{memory_total} // 0.0;
                        $memory_total .= '.0' if ( $memory_total =~ /^\d+$/ );
                        my $fullest_disk =
                          $i->{summary}->{fullest_disk} // 0.0;
                        $fullest_disk .= '.0' if ( $fullest_disk =~ /^\d+$/ );
                        my $fullest_disk_free =
                          $i->{summary}->{fullest_disk_free} // 0.0;
                        $fullest_disk_free .= '.0' if ( $fullest_disk_free =~ /^\d+$/ );
                        my (
                            $regionname, $servicename, $client, $envname
                        );

                        $regionname  = $row->{REGIONNAME};
                        $envname  = $row->{ENVNAME};
                        $servicename = $row->{SERVICENAME};
                        $client      = $row->{CLIENT};
						
                        $line .= data2line(
                            'servers_status',
                            {
                                cpu       => ${cpu},
                                cpu_stolen      => ${cpu_stolen},
                                disk_io => ${disk_io},
								memory => ${memory},
								memory_used => ${memory_used},
								memory_total => ${memory_total},
								fullest_disk => ${fullest_disk},
								fullest_disk_free => ${fullest_disk_free}
                            },
                            {
                                name        => $i->{name},
                                regionname  => $regionname,
								envname     => $envname,
                                servicename => $servicename,
                                client      => $client
                            }
                        );

                        $line .= "\n";
                    }
                }
            }
            chomp $line;
            #say $line;
            send_to_influx($line);
        }

    );
    $c->render( text => 'ok' );
};


get '/nr_nginx_cmdb' => sub {
    my $c        = shift;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
	my $cmdb_sql_nginx = $cmdb_sql . qq| WHERE APPTYPE = 'nginx-lb'|; 
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql_nginx, { Slice => {} } );

    $c->ua->get(
        $newrelic_components => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;

            for my $row (@$data_ref) {
                foreach my $i ( @{ $tx->res->json->{components} } ) {
                    if ( ($row->{APPNAME} eq $i->{name}) ) {

                        my $total_request_rate = $i->{summary_metrics}[0]->{values}->{raw};
                        $total_request_rate .= '.0' if ( $total_request_rate =~ /^\d+$/ );
                        my $active_connections = $i->{summary_metrics}[1]->{values}->{raw};
                        $active_connections .= '.0' if ( $active_connections =~ /^\d+$/ );
                        my $connection_drop_rate =
                          $i->{summary_metrics}[2]->{values}->{raw};
                        $connection_drop_rate .= '.0' if ( $connection_drop_rate =~ /^\d+$/ );
                        my $description = $row->{DESCRIPTION};
                        my $regionname  = $row->{REGIONNAME};
						my $envname  = $row->{ENVNAME};
                        my $servicename = $row->{SERVICENAME};
                        my $serviceid   = $row->{SERVICID};
                        my $client      = $row->{CLIENT};

                        $line .= data2line(
                            'nginx_status',
                            {
                                total_request_rate      => ${total_request_rate},
                                active_connections      => ${active_connections},
                                connection_drop_rate => ${connection_drop_rate},
                            },
                            {
                                name        => $i->{name},
                                regionname  => $regionname,
								envname  => $envname,
                                servicename => $servicename,
                                client      => $client
                            }
                        );
                    }
                }
                $line .= "\n";
            }
            chomp $line;
            #say $line;
            send_to_influx($line);
        }

    );
    $c->render( text => 'ok' );
};


get '/logmet_redirect' => sub {
    my $c            = shift;
    my $container    = $c->param('container') || '';
    my $dbh          = DBI->connect( $dsn, $uid, $pwd );
    my $sql          = "$logmet_sql where APPNAME = \'$container\'";
    my $dashboard_id = $dbh->selectrow_array( $sql, undef );
    #say $dashboard_id;
    unless ($dashboard_id) {
        $c->render( text =>
"Logmet dashboard id not found in cmdb database for container $container"
        );
    }
    $c->redirect_to(
        "https://logmet.eu-gb.bluemix.net/grafana/#/dashboard/db/$dashboard_id"
    );
};


sub get_container_data {

    my $c = shift;
	$c = $c->inactivity_timeout(60);
    my $bluemix_auth = shift;
	my $bmx_containers_api = shift;
    my $bmx_space_guid = shift;
	my $data_ref = shift;

    my %inst_num;
	my %group_status;
    my $inst_num;
	my $group_status;
	
    my $line     = '';
	
    $c->ua->post(
        $bluemix_auth => { Authorization => 'Basic Y2Y6' } => form => {
            grant_type => 'password',
            username   => $bmx_username,
            password   => $bmx_password
          } => sub {
            my ( $ua, $tx ) = @_;
            my $bmx_access_token = $tx->res->json->{access_token};
            $c->ua->get(
                $bmx_containers_api => {
                    'X-Auth-Token'      => "bearer $bmx_access_token",
                    'X-Auth-Project-Id' => $bmx_space_guid
                  } => sub {
                    my ( $ua, $tx ) = @_;
                    my ( $type, $group );
					#say Dumper($tx->res->json);
                    foreach my $i ( @{ $tx->res->json } ) {
                        if ( $i->{Group}->{Name} ) {
                            $type  = 'ic_group';
                            $group = $i->{Group}->{Name};
                            $inst_num{$group}++;
							if($i->{Status} eq 'Running') {
								$group_status{$group}++;
							}
							
                        }
                        else {
                            $type  = 'ic_single';
                            $group = $i->{Name};
                        }

                        my (
                            $description, $regionname, $servicename,
                            $serviceid,   $client, $apptype, $envname
                        );

                        for my $row (@$data_ref) {
#							say $row->{APPNAME} . " , " . $group;
                            if ( $row->{APPNAME} eq $group ) {
                                $description = $row->{DESCRIPTION};
                                $regionname  = $row->{REGIONNAME};
                                $envname     = $row->{ENVNAME};
                                $servicename = $row->{SERVICENAME};
                                $serviceid   = $row->{SERVICID};
                                $client      = $row->{CLIENT};
								$apptype	 = $row->{APPTYPE};
                            }
                        }
												
                        if ( $inst_num{$group} ) {
                            #$inst_num = $inst_num{$group} . '.0';
							$inst_num = $inst_num{$group};
                        }
                        else {
                            #$inst_num = '1.0';
							$inst_num = 1;
                        }

						if($group_status{$group}) {
							if($group_status{$group} == 0 ) {
								$group_status = 0;
							} elsif ($group_status{$group} < $inst_num){
								$group_status = 1;
							} else {
								$group_status = 2;
							}
						}
						
                        if($apptype) {
					    #say "I'm an apptype!  " . $i->{Name};
						$line .= data2line(
                            'container_status',
                            {
                                status     => $i->{Status},
                                started    => $i->{Started},
                                memory     => $i->{Memory},
                                inst_index => $inst_num,
								group_status => $group_status

                            },
                            {
                                ic_name     => $i->{Name},
                                ic_group    => $group,
                                type        => $type,
                                regionname  => $regionname,
								envname     => $envname,
                                servicename => $servicename,
                                client      => $client,
								apptype     => $apptype

                            }
                        );
						
					}
						#say "I'm not! " . $group . "\n";
						
                        $line .= "\n";
                    }
					say "Line = " . $line . "\n";
                    chomp $line;
					send_to_influx($line);
				}
			);
		}
	);
#	say "Line2 = " . $line;
#    return ($line);
	
}

get '/container_status' => sub {
    my $c = shift;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );
    $c->inactivity_timeout(60);
	get_container_data ($c, $bluemix_auth, $bmx_containers_api_us, $bmx_space_guid_us_prod, $data_ref);
	get_container_data ($c, $bluemix_auth, $bmx_containers_api_eugb, $bmx_space_guid_eugb_prod, $data_ref);
	get_container_data ($c, $bluemix_auth, $bmx_containers_api_us, $bmx_space_guid_us_integ, $data_ref);
	get_container_data ($c, $bluemix_auth, $bmx_containers_api_eugb, $bmx_space_guid_eugb_integ, $data_ref);
	get_container_data ($c, $bluemix_auth, $bmx_containers_api_us, $bmx_space_guid_us_qa, $data_ref);
	get_container_data ($c, $bluemix_auth, $bmx_containers_api_eugb, $bmx_space_guid_eugb_qa, $data_ref);
    #send_to_influx($line);
    $c->render( text => "ok" );
};

sub get_app_status {

    my $c = shift;
    my $bluemix_auth = shift;
	my $bmx_apps_api = shift;
	my $bmx_access_token = shift;

    my $line = '';
    my $status_num;	
	$c->ua->get(
		$bmx_apps_api => {
			'Authorization' => "bearer $bmx_access_token"
		  } => sub {
			my ( $ua, $tx ) = @_;
			foreach my $i ( @{ $tx->res->json->{apps} } ) {
				#say $i ->{name};
				$status_num = 0 if $i->{state} eq 'STARTED';
				$status_num = 1 if $i->{state} eq 'STOPPED';
				$line .= data2line(
					'bmx_app_status',
					{
						status            => $i->{state},
						status_num        => $status_num,
						instances         => $i->{instances},
						running_instances => $i->{running_instances}
					},
					{
						cf_name => $i->{name},
					}
				);

				$line .= "\n";
			}
		
			#say $line;
			chomp $line;
			send_to_influx($line);
		}
	 
	);	
	
}

get '/bmx_app_status' => sub {
    my $c    = shift;
    $c->ua->post(
        $bluemix_auth => { Authorization => 'Basic Y2Y6' } => form => {
            grant_type => 'password',
            username   => $bmx_username,
            password   => $bmx_password
          } => sub {
            my ( $ua, $tx ) = @_;
            my $bmx_access_token = $tx->res->json->{access_token};
     		get_app_status ($c, $bluemix_auth, $bmx_apps_api_us_prod, $bmx_access_token);
     		get_app_status ($c, $bluemix_auth, $bmx_apps_api_eugb_prod, $bmx_access_token);
     		get_app_status ($c, $bluemix_auth, $bmx_apps_api_us_integ, $bmx_access_token);
     		get_app_status ($c, $bluemix_auth, $bmx_apps_api_eugb_integ, $bmx_access_token);
     		get_app_status ($c, $bluemix_auth, $bmx_apps_api_us_qa, $bmx_access_token);
     		get_app_status ($c, $bluemix_auth, $bmx_apps_api_eugb_qa, $bmx_access_token);
        }
    );
    $c->render( text => "ok");
};

get '/noi_app_severity' => sub {
    my $c = shift;
    my %event_num;
    my $line = '';
    my $highest_sev;
    my $dbh = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );
    $c->ua->post(
        $noi_api => {
            'Accept'       => 'application/json',
            'Content-Type' => 'application/json',
            'charset'      => 'UTF-8'
          } => json => { sqlcmd => $noi_sql } => sub {
            my ( $ua, $tx ) = @_;

            for my $row (@$data_ref) {
                foreach my $i ( @{ $tx->res->json->{rowset}->{rows} } ) {
                    if ( $row->{APPNAME} eq $i->{Node} ) {
                        $event_num{ $i->{Node} }{crit}++
                          if ( $i->{Severity} == 5 );
                        $event_num{ $i->{Node} }{major}++
                          if ( $i->{Severity} == 4 );
                        $event_num{ $i->{Node} }{minor}++
                          if ( $i->{Severity} == 3 );
                        $event_num{ $i->{Node} }{warn}++
                          if ( $i->{Severity} == 4 );
                        $event_num{ $i->{Node} }{inter}++
                          if ( $i->{Severity} == 1 );
                        $event_num{ $i->{Node} }{clear}++
                          if ( $i->{Severity} == 0 );
                    }
                }
                $event_num{ $row->{APPNAME} }{clear}++;
				$event_num{ $row->{APPNAME} }{regionname} = $row->{REGIONNAME};
				$event_num{ $row->{APPNAME} }{apptype} = $row->{APPTYPE}; 
            }

            for my $i ( keys %event_num ) {
                if ( $event_num{$i}{crit} ) {
                    $highest_sev = 5;
                    #say "$i:5";
                }
                elsif ( $event_num{$i}{major} ) {
                    $highest_sev = 4;
                    #say "$i:4";
                }
                elsif ( $event_num{$i}{minor} ) {
                    $highest_sev = 3;
                    #say "$i:3";
                }
                elsif ( $event_num{$i}{warn} ) {
                    $highest_sev = 2;
                    #say "$i:2";
                }
                elsif ( $event_num{$i}{inter} ) {
                    $highest_sev = 1;
                    #say "$i:1";
                }
                else {
                    $highest_sev = 0;
                    #say "$i:0";
                }
                $line .= data2line(
                    'noi_app_severity',
                    {
                        highest_sev => $highest_sev
                    },
                    {
                        app_name => $i,
						apptype => $event_num{$i}{apptype},
						regionname => $event_num{$i}{regionname}
						
                    }
                );
                $line .= "\n";
            }
            chomp $line;
            #say $line;
            send_to_influx($line);
        }
    );

    $c->render( text => 'ok' );
};


#sends request to New Relic API and prints ASCII table
get '/list' => sub {
    my $c = shift;
    my $dbh = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref =
      $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );

    my $t =
      Text::ASCIITable->new( { headingText => 'New Relic Service Status' } );
    $t->setCols(
        "Name",   "Id",       "Region Name", "Service Name",
        "Client", "Language", "Status",      "Response time",
        "Error rate"
    );
    my $headers = { Accept => 'application/json' };
    $c->ua->get(
        $newrelic_url => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;
            foreach my $i ( @{ $tx->res->json->{applications} } ) {
                my $error_rate = $i->{application_summary}->{error_rate} || '-';
                my $response_time =
                  $i->{application_summary}->{response_time} || '-';
                my $language = $i->{language};
                my $status = $i->{health_status} || '-';
                my (
                    $description, $regionname, $servicename,
                    $serviceid,   $client
                );
                for my $row (@$data_ref) {
                    if ( $row->{APPID} == $i->{id} ) {
                        $description = $row->{DESCRIPTION};
                        $regionname  = $row->{REGIONNAME};
                        $servicename = $row->{SERVICENAME};
                        $serviceid   = $row->{SERVICID};
                        $client      = $row->{CLIENT};
                    }
                }

                $t->addRow(
                    "$i->{name}", "$i->{id}",
                    $regionname,  $servicename,
                    $client,      $language,
                    $status,      $response_time,
                    $error_rate
                );
            }

            $c->render( text => $t );
        }
    );

};

get '/html' => sub {
    my $c       = shift;
    my $headers = { Accept => 'application/json' };
    my $dbh     = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref =
      $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );

    my $table = new HTML::Table( -class => 'sortable' );
    $table->addSectionRow(
        'thead',         0,        "Name",     "Region Name",
        "Service Name",  "Client", "Language", "Status",
        "Response time", "Error rate"
    );

    $c->ua->get(
        $newrelic_url => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;
            my $row = 0;
            foreach my $i ( @{ $tx->res->json->{applications} } ) {
                my $error_rate = $i->{application_summary}->{error_rate} || '-';
                my $response_time =
                  $i->{application_summary}->{response_time} || '-';
                my $language = $i->{language};
                my $status = $i->{health_status} || '-';
                my (
                    $description, $regionname, $servicename,
                    $serviceid,   $client
                );
                for my $row (@$data_ref) {
                    if ( $row->{APPID} == $i->{id} ) {
                        $description = $row->{DESCRIPTION};
                        $regionname  = $row->{REGIONNAME};
                        $servicename = $row->{SERVICENAME};
                        $serviceid   = $row->{SERVICID};
                        $client      = $row->{CLIENT};
                    }
                }
                $table->addRow(
                    "$i->{name}", $regionname, $servicename,   $client,
                    $language,    $status,     $response_time, $error_rate
                );

            }
            $table->sort( 6, 'ALPHA', 'ASC' );
            my $row_num = $table->getTableRows;
            for ( 1 .. $row_num ) {

                #say $table->getCell($_,6);
                $table->setRowBGColor( $_, $table->getCell( $_, 6 ) );

            }
            $c->stash( table => $table );
            $c->render('ms-status-html-table');
        }
    );
};

app->start;
__DATA__

@@ ms-status-html-table.html.ep
<!DOCTYPE html>
<head>
<meta http-equiv="refresh" content="30" >
	 %= javascript '/js/sorttable.js'
	 <style>
	 .datagrid table { border-collapse: collapse; text-align: left; width: 100%; } 
	 .datagrid {font: normal 12px/150% Arial, Helvetica, sans-serif; background: #fff; overflow: hidden; border: 1px solid #006699; -webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px; }
	 .datagrid table td { padding: 4px 6px; }
	 .datagrid table thead {background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #006699), color-stop(1, #00557F) ); background:-moz-linear-gradient( center top, #006699 5%, #00557F 100% );filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#006699', endColorstr='#00557F');background-color:#006699; color:#FFFFFF; font-size: 14px; font-weight: bold; border-left: 1px solid #0070A8; } 
	 .datagrid table tbody td { color: #000000; border-left: 1px solid #E1EEF4;font-size: 14px;font-weight: normal; }

	 </style>
	   
</head>
<html>

  <body>
<div class='datagrid'>
<%== $table %>
</div>

</html>

