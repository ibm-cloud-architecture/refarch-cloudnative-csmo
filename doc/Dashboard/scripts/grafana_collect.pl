#!/usr/bin/env perl
use Mojolicious::Lite;
use Data::Dumper;
use JSON;
use Text::ASCIITable;
use InfluxDB::LineProtocol qw(data2line line2data);
use Hijk;
use HTML::Table;
use DBI;

############### Edit section below ###############################################################
my $api_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';    # New relic API Key
my $bmx_space_guid =
  'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';   # cf space cloudnative-dev --guid

my $noi_user     = "xxxx";                     # Omnibus user
my $noi_password = "xxxxxxxxx";                # Ominbus user password
my $noi_api =
"http://${noi_user}:${noi_password}\@xxx.xxx.xxx.xxx:8080/objectserver/restapi/sql/factory/";

# insert Netcool Omnibus IP address above
my $bmx_username = 'xxxxxxxxxxxxxxxx';         # Bluemix user id
my $bmx_password = 'xxxxxxxx';                 # Bluemix user password
my $influx_host = 'localhost';    # change is InfluxDB is installed remotely
my $influx_port = '8086';         # change is Inlfux DB port is non-default
my $uid         = "cmdb";         # MySQL user for CMDB database
my $pwd         = 'cmdb';         # MySQL user password
####################################################################################################

#my $dsn          = "DBI:DB2:BMXCMDB";
my $dsn = "DBI:mysql:database=cmdb;host=localhost";

my $newrelic_url        = 'https://api.newrelic.com/v2/applications.json';
my $newrelic_components = 'https://api.newrelic.com/v2/components.json';
my $bluemix_auth = 'https://login.ng.bluemix.net/UAALoginServerWAR/oauth/token';
my $bmx_containers_api =
  'https://containers-api.eu-gb.bluemix.net/v3/containers/json';

my $bmx_container_group =
  'https://containers-api.eu-gb.bluemix.net/v3/containers/groups';

#  'f5e787de-e25e-4b1b-9248-37065421ccc9'
my $logmet_dash_search =
'https://logmet.eu-gb.bluemix.net/elasticsearch/grafana-dash/dashboard/_search';

my $bmx_apps_api =
  "https://api.eu-gb.bluemix.net/v2/spaces/${bmx_space_guid}/summary";

my $noi_sql =

#'select Serial, Node, Service, to_char(LastOccurrence), Severity from alerts.status where Severity >= 5';
'select Serial, Node, Service, to_char(LastOccurrence), Severity from alerts.status';

my $cmdb_sql =

#"select APPNAME,APPID,REGIONNAME,CLIENT,DESCRIPTION,SERVICENAME,SERVICEID from BMXCMDB_SERVICEMAP";
"select APPNAME,APPTYPE,APPID,REGIONNAME,CLIENT,DESCRIPTION,SERVICENAME,SERVICEID from cmdb";

my $logmet_sql = "select LOGMET_GRAFANA_ID from cmdb";

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
    print F scalar(localtime) . " POST to inlux $res->{status}\n";
    if ( $res->{status} != 204 ) {
        print F scalar(localtime) . " POST to inlux line: $line\n";
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
        print F scalar(localtime) . " RETRY!!!! POST to inlux $res->{status}\n";
        print F scalar(localtime) . " POST to inlux line: $line\n";
    }
    close F;
}

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
                            $serviceid,   $client,     $apptype
                        );

                        $description = $row->{DESCRIPTION};
                        $regionname  = $row->{REGIONNAME};
                        $servicename = $row->{SERVICENAME};
                        $serviceid   = $row->{SERVICID};
                        $client      = $row->{CLIENT};
                        $apptype     = $row->{APPTYPE};

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
                                apptype     => $apptype
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
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );

    $c->ua->get(
        $newrelic_components => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;

            for my $row (@$data_ref) {
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

get '/nr_nginx_cmdb' => sub {
    my $c        = shift;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );

    $c->ua->get(
        $newrelic_components => { 'X-Api-Key' => $api_key } => sub {
            my ( $ua, $tx ) = @_;

            for my $row (@$data_ref) {
                foreach my $i ( @{ $tx->res->json->{components} } ) {
                    if (    ( $row->{APPNAME} eq $i->{name} )
                        and ( $i->{name} eq 'nginx-lb' ) )
                    {

                        my $total_request_rate =
                          $i->{summary_metrics}[0]->{values}->{raw};
                        $total_request_rate .= '.0'
                          if ( $total_request_rate =~ /^\d+$/ );
                        my $active_connections =
                          $i->{summary_metrics}[1]->{values}->{raw};
                        $active_connections .= '.0'
                          if ( $active_connections =~ /^\d+$/ );
                        my $connection_drop_rate =
                          $i->{summary_metrics}[2]->{values}->{raw};
                        $connection_drop_rate .= '.0'
                          if ( $connection_drop_rate =~ /^\d+$/ );
                        my $description = $row->{DESCRIPTION};
                        my $regionname  = $row->{REGIONNAME};
                        my $servicename = $row->{SERVICENAME};
                        my $serviceid   = $row->{SERVICID};
                        my $client      = $row->{CLIENT};

                        $line .= data2line(
                            'ngnix_status',
                            {
                                total_request_rate   => ${total_request_rate},
                                active_connections   => ${active_connections},
                                connection_drop_rate => ${connection_drop_rate},
                            },
                            {
                                name        => $i->{name},
                                regionname  => $regionname,
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

get '/container_status' => sub {
    my $c = shift;
    my %inst_num;
    my %group_status;
    my $inst_num;
    my $group_status;
    my $line     = '';
    my $dbh      = DBI->connect( $dsn, $uid, $pwd );
    my $data_ref = $dbh->selectall_arrayref( $cmdb_sql, { Slice => {} } );
    $c->inactivity_timeout(60);
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

                    foreach my $i ( @{ $tx->res->json } ) {

                        if ( $i->{Group}->{Name} ) {

                            $type  = 'ic_group';
                            $group = $i->{Group}->{Name};
                            $inst_num{$group}++;
                            if ( $i->{Status} eq 'Running' ) {
                                $group_status{$group}++;
                            }

                        }
                        else {
                            $type  = 'ic_single';
                            $group = $i->{Name};
                        }

                        my (
                            $description, $regionname, $servicename,
                            $serviceid,   $client,     $apptype
                        );

                        for my $row (@$data_ref) {
                            if ( $row->{APPNAME} eq $group ) {
                                $description = $row->{DESCRIPTION};
                                $regionname  = $row->{REGIONNAME};
                                $servicename = $row->{SERVICENAME};
                                $serviceid   = $row->{SERVICID};
                                $client      = $row->{CLIENT};
                                $apptype     = $row->{APPTYPE};
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

                        if ( $group_status{$group} ) {
                            if ( $group_status{$group} == 0 ) {
                                $group_status = 0;
                            }
                            elsif ( $group_status{$group} < $inst_num ) {
                                $group_status = 1;
                            }
                            else {
                                $group_status = 2;
                            }
                        }

                        if ($apptype) {
                            $line .= data2line(
                                'container_status',
                                {
                                    status       => $i->{Status},
                                    started      => $i->{Started},
                                    memory       => $i->{Memory},
                                    inst_index   => $inst_num,
                                    group_status => $group_status

                                },
                                {
                                    ic_name     => $i->{Name},
                                    ic_group    => $group,
                                    type        => $type,
                                    regionname  => $regionname,
                                    servicename => $servicename,
                                    client      => $client,
                                    apptype     => $apptype

                                }
                            );
                        }
                        $line .= "\n";
                    }
                    chomp $line;

                    #say $line;
                    send_to_influx($line);
                    $c->render( text => 'ok' );
                }
            );

        }
    );
};

get '/bmx_app_status' => sub {
    my $c    = shift;
    my $line = '';
    my $status_num;
    $c->ua->post(
        $bluemix_auth => { Authorization => 'Basic Y2Y6' } => form => {
            grant_type => 'password',
            username   => $bmx_username,
            password   => $bmx_password
          } => sub {
            my ( $ua, $tx ) = @_;

            my $bmx_access_token = $tx->res->json->{access_token};

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
    );

    $c->render( text => 'ok' );
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
                        app_name => $i
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

## Routes (/query and /search) are created for Grafana Simple JSON data source. Not used at the moment by the current dashboard

my $s = [
    "instrumented-inventory-group12", "zuul_cluster",
    "upper_75",                       "upper_90",
    "upper_95"
];

any '/query' => sub {
    my $c = shift;
    my $size;
    my $target = $c->req->json->{scopedVars}->{ContainerGroupName}->{value};
    $c->inactivity_timeout(60);
    $c->ua->post(
        $bluemix_auth => { Authorization => 'Basic Y2Y6' } => form => {
            grant_type => 'password',
            username   => $bmx_username,
            password   => $bmx_password
          } => sub {
            my ( $ua, $tx ) = @_;

            my $bmx_access_token = $tx->res->json->{access_token};

            $c->ua->get(
                "${bmx_container_group}/${target}" => {
                    'X-Auth-Token'      => "bearer $bmx_access_token",
                    'X-Auth-Project-Id' => $bmx_space_guid
                  } => sub {
                    my ( $ua, $tx ) = @_;
                    my ( $type, $group );

                    #say Dumper( $tx->res->json );
                    $size = $tx->res->json->{NumberInstances}->{CurrentSize};
                    $c->render(
                        json => [
                            {
                                "target"     => $target,
                                "datapoints" => [ [ $size, 99 ] ]
                            }
                        ]
                    );
                }
            );
        }
    );

};

any '/search' => sub {
    my $c = shift;

    $c->render( json => $s );
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

