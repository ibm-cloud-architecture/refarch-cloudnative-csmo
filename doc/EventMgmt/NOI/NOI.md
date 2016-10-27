# Netcool Operations Insight event management for Hybrid application

IBM Netcool Operations Insight accelerates the operations management lifecycle from problem detection to fix. It receives events from ressource monitoring solutions, enriches, correlates and escalates those based on automation rules.

![System Context Flow](NOI system context flow.png?raw=true)  

In this document you will understand how to setup IBM Netcool® Operations Insight (NOI) in the middle of the service management tool chain and demonstrate the interaction of NOI with the other tool chain components of the toolchain for operating the BlueCompute hybrid application.

**Note**: We will not cover standard installation and operation of NOI, since this is not unique to the Bluemix environment, but we will link to appropriate references. 
We will also link to the guide [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight) for details about the integration with Bluemix.


Netcool Operations Insight is operated though a web based GUI called DASH, login is 

    https://{yourServer}:{port}/ibm/console.

Replace {yourServer} and {port} with the address/port of your NOI DASH instance.

Netcool Operations Insight Impact is administered though a web based GUI called Impact-UI, login is 

    https://{yourServer}:{port}/ibm/console.

Replace {yourServer} and {port} with the address/port of your NOI Impact instance.

##Step 1: Install and Setup IBM Netcool Operations Insight

For base setup of an NOI instance, please follow the information of guide [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight).

##Step 2: Enable event reception for New Relic incidents send as webhooks

The integration is based on New Relic's webhook capabilities. The New Relic events are received by means of the Netcool Omnibus message bus probe. For reading and parsing the New Relic json format, there are some probe configuration files prepared.

### Message bus probe configuration    

1. Install the message bus probe per the [standard IBM instructions](https://www.ibm.com/support/knowledgecenter/SSSHTQ/omnibus/probes/message_bus/wip/concept/messbuspr_intro.html) and adjust by any local requirements (mail server considerations, H/A considerations, etc.) 

    __Note:__ the lowest version of the probe that supports New Relic integration is 1.3. For integrating the new Alerts webhooks, you need to use the message bus probe version 1.3.0.5 or higher.

    [Learn more about the probe for message bus.](http://www-01.ibm.com/support/docview.wss?uid=swg21970413)

2. Clone git repository.

    `# git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo.git`
    
    `# cd refarch-cloudnative-csmo`

    Since this instance of the message bus probe will only support New Relic events, it is assumed that all 
probe files will have a suffix of _newrelic and that the probe name will be message_bus_newrelic. The 
included configuration files follow this format, but you are free to change them to suit your own local 
standards.

#### Setup of messagebus_newrelic.props:    
1. Copy the included file [`message_bus_newrelic.props`](/scripts/EventMgmt/NOI/probes/arch/message_bus_newrelic.props) to `$OMNIHOME/probes/{arch}/message_bus_newrelic.props` on your probe server. 

    Replace the {arch} with your platform type running the probe. For example 
    
    `$OMNIHOME/probes/linux2x86/message_bus_newrelic.props`

    Make any necessary changes to the file, such as matching the ObjectServer name to your local ObjectServer (Attribute: `Server`). 
    
2. Remember to restart the probe after changing the props files. 
    
#### Setup of httpTransport_newrelic.properties:
1. Copy the included file [`httpTransport_newrelic.properties`](/scripts/EventMgmt/NOI/java/conf/httpTransport_newrelic.properties) to `$OMNIHOME/java/conf/httpTransport_newrelic.properties` on your probe server.

    Make any necessary changes to the `httpTransport_newrelic.properties` file, such as choosing a suitable 
port and define sfurther ecurity settings.  
    
    
2. Remember to restart the probe after changing the properties files.

#### Setup of messagebus_newrelic.rules:    
1. Copy the included file [`message_bus_newrelic.rules`](/scripts/EventMgmt/NOI/probes/arch/message_bus_newrelic.rules) to `$OMNIHOME/probes/{arch}/message_bus_newrelic.rules` on your probe server.

    Replace the {arch} with your platform type running the probe. For example `$OMNIHOME/probes/linux2x86/message_bus_newrelic.rules `

    The included rules file is a default set of rules for New Relic integration. You may have to adjust it to suit 
your local standards for rules files. 

2. Remember to reload the probe rules (or restart the probe) after changing the rules files. 


##Step 3: Install and Setup enrichment database 
Incoming events will be enriched with information about their business service and location to allow an easier view on business services likes _BlueCompute_ and the source of the hybrid application. This additional information is important as other tools of the tool chain will need this kind of information for better aligned operation. For example the Runbook automation will need the information about where the component is hosted to use the correct execution route for running the runbook.

The enrichment data source has been prepared as a MySQL database, which will be accessed by NOI. Incoming events are retrieved, enriched with the information from the database before escalation and other automations will be triggered.

The database can be exchanged by any other existing configuration data source which provides the same data set of information, for example an IBM Control Desk CMDB.
      

1. Install and setup a MySQL enrichment database.

    For detailed steps please continue with [Installing MySQL](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/tree/master/doc/Dashboarding/Grafana#mysql)
    
2. Install and setup the MySQL maintenance PHP UI

    For detailed steps please continue with [Installing PHP](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Dashboarding/Grafana#php)
    
3. Add application instances for your _BlueCompute_ environment into the database

    + Either add them manually via the PHP UI for MySQL:

         i) Connect to the maintenande UI (php) for managing the database content at 
         
            `http://{your-serrver}/cmdb.php`
        
            Replace the {your-server} with the address of your enrichment database server running the PHP ui.
        
         ii) Use the "Add" button to add new entry
        
         iii) Fill in the form with
         
              APPID        - an unique ID for this configuration item for internal database use, the New Relic id for the item can be used for example
              APPNAME      - the name of the application component as provided by the monitoring sources like `bluecompute-web-app`
              APPTYPE      - type of application like `node.js`, `java`, `mysql`,...
              REGIONAME    - tag for the location like `bmx_eu-gb`, `sl_us`,...
              CLIENT       - name of client the application belongs to
              DESCRIPTION  - short description about the application entry, like `bluecompute web application`
              SERVICENAME  - associated business service name the application component belongs to like `BlueCompute`
              SERVICEID    - id for the business service, the New Relic service map id can be used for example
                
                   
    + or import them with a mysql script:
    
        Use a script similar to the [cmdb.sql script](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Dashboarding/Grafana/scripts/cmdb.sql) with your custom entries
    
    
##Step 4: Enrich events with enrichment database

The Impact component of NOI will use this enrichment database to enrich incoming events. You need three Impact configurations to achieve this:

+ Impact DataSource `BMXCMDB` accessing the MySQL database 

+ Impact Policy `EnrichEventWithBMXCMDB` to find a match in the database for the node name of an incoming event and updating the fields _Service_,_Location_,_ScopeId_ and _CASE_Client_ accordingly.

+ Impact Service `CASE_Omnibus_BMX_Enrich` which runs with Netcool Omnibus start, triggering the policy above for each newly reveiced event having set `CASE_BMX_CMDB=1`. For New Relic events this will be set on the probe level when parsing the incoming incident event.

The configuration can be imported into your Netcool Impact instance.

1. Copy the included file [`case_impact_enrichment_project.tgz`](/scripts/EventMgmt/NOI/impact/case_impact_enrichment_project.tgz) to `/tmp` on your impact server.

2. Extract project on your impact server

    `# cd /tmp`
    
    `# tar xzf case_impact_enrichment_project.tgz`

3. Import the `CSMO-Enrichment` project into your Impact server

    `# $NCHOME/bin/nci_import {server_name} /tmp/case_impact_enrichment_project`
    
     Replace the {server_name} with the name of your Impact server instance and $NCHOME with the base directory of your Impact installation.
     
     Example: 
     
     `# /opt/IBM/tivoli/impact/bin/nci_import NCI /tmp/case_impact_enrichment_project`
    
4. Log into the Impact UI and change the connection information of your `BMXCMDB` datasource with your `Username`, `Password`, `Hostname`, `Port` and your desired `Database Failure Policy` via the Impact UI.

    Default settings in the project are: 
    
    + Username=cmdb 
    + Password=cmdb 
    + Hostname=159.8.41.178 
    + Port=3306 
    + Database Failure Policy=Disable Backup


##Step 5: Create View and Filter for _BlueCompute_

When the events are enriched with the data from the enrichment database, event viewer _views_ and _filters_ can be defined to use the enrichment information accordingly.


 
The configuration can be imported into your NOI DASH instance. For additional details refer to the [product information](https://www.ibm.com/support/knowledgecenter/SSSHTQ_8.1.0/com.ibm.netcool_OMNIbus.doc_8.1.0/webtop/wip/task/web_adm_expimpimportdata.html).

1. Copy the included file [`case_webgui_filter_and_views.zip`](/scripts/EventMgmt/NOI/webgui/case_webgui_filter_and_views.zip) to `$JazzSM_HOME/ui/input/data.zip` on your NOI DASH server.

    where $JazzSM_HOME is the home directory of your DASH installation, like `/opt/IBM/JazzSM`.
    
    __Note:__ If you have changed the `import.importFile` statement in the `$WEBGUI_HOME/integration/importexport_tool/etc/OMNIbusWebGUI_settings.properties` configuration file, move the `data.zip` to the specified directory accordingly.

2. Import filter and view into your NOI DASH server

    `# cd $JazzSM_HOME/ui/bin`
    
    `# ./consolecli.sh Import --username {smadmin} --password {password} --excludePlugins ImportPagePlugin,ChartImportPlugin --settingFile $WEBGUI_HOME/integration/importexport_tool/etc/OMNIbusWebGUI_settings.properties`

    where $WEBGUI_HOME is the home directory of your WebGui installation, like `/opt/IBM/netcool/gui/omnibus_webgui`, {smadmin} your WebSphere administrative user and {password} the password of this user.
    
    This will create a WebGui view `CASE_Integrations` and a filter `BlueCompute`.
   

##Step 6: View application events for _BlueCompute_

Upon login into your DASH instance, you access the list of active events through the "Incident -> Event Viewer" menu.

The list of events displayed is controlled by a _filter_. You may, for example, wish to see only events related to a specific application or you may wish to see all the events which occurred in the last 10 minutes.

+ The imported filter `BlueCompute` displays all events for the _BlueCompute_ business service based on the event field setting "Service=BlueCompute".
 
The format of the event viewer list is controlled by the assigned _view_. 

+ The view `Case_Integrations` displays all events in a tree grouping form, where the first tree level is “Service” and the second tree level “Location”.  
    
As a result of step 3 and 4, these used fields have been enriched for each technical event based on the enrichment data source.

By this you can immediately see all affected services including the _BlueCompute_ application and sub-grouped by location. 
In the following screenshot There are two events with _BlueCompute_ application components running on EU Bluemix region (bmx_eu-gb) and on Softlayer (SL).

![BlueCompute event in NOI](NOI_events_for_bluecompute.png?raw=true)  


With this view, you can also see which critical events have been forwarded to ANS, Slack and/or ICD trouble ticketing sytem. You can also see which Slack channel has been updated. Events can either be forwarded automatically when they are first reported or manually through operator intervention. 
For activities like forwarding events manually or automatically to a slack channel, see the [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight).

##Step 7: Forward critical events to alert notification system

Forwarding critical events to the IBM Alert Notification System (ANS) is done **automatically** with Netcool Impact policies. Alerts will be send with ANS field `ApplicationsOrServices` set to value of NOI field `Service`. Users can manually send events to ANS by means of the event context menu.


You need four Impact configuration file to achieve this:

+ Impact DataSource `defaultobjectserver` accessing the Omnibus event database 

+ Impact Policy `SendAlertsToAlertNotification` to send alerst to ANS.

+ Impact Policy `DeleteAlertsFromAlertNotification` to remove alerts from ANS, if event has been cleared.

+ Impact Service `AlertNotificationService` which runs with Netcool Omnibus start, triggering the policies above for each newly received or changed events. 


There are no specific steps, which are related to _BlueCompute_ hybrid application.
Use the guide [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight) for a detailed description about defining this ANS integration and using the configuration files.

**Note**: the target documentation about the ANS integration is in progress.

##Step 8: Forward events to collaboration tool

Forwarding events to the collaboration tool Slack is done via Netcool Impact policies, when triggered by an user via a send-request from the NOI eventviewer context menu. 

There are no specific steps, which are related to _BlueCompute_ hybrid application for integrating with Slack.
Use the guide [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight) for a detailed description about defining this integration.


### As a First Responder forward manually an event to a specific Slack channel:

In this case the FirstResponder uses an _existing_ channel which is reused for multiple purposes.

1. View the alert in the eventviewer

2. Right-click on the event to open the context menu.

3. Select the `Slack->Send to Specific Channel` entry 

    ![SendToSpecificChannel](NOI_send_to_specific_channel.png?raw=true) 

4. Enter the channel name, which should receive the BlueCompute event for further collaboration and click `Run` button. Example: `cloud-operations-mon`.

    ![SelectChannelName](NOI_select_target_channel_name.png?raw=true) 

    You can decide if you create a channel for all _BlueCompute_ events or for all critical monitoring events depending on the way you prefer to collaborate on those incidents.


### As a First Responder forward manually an event to an automatic Slack channel:

In this case the FirstResponder creates automatically a _new_ channel for an individual event and invites subject matter experts and incident owners into the channel to start collaboration.

1. View the alert in the eventviewer

2. Right-click on the event to open the context menu.

3. Select the `Slack->Send to Automatic Channel` entry 

   This will create a new channel with channel name `inc_{serial}_{node}` where the values of the event fields `Serial` and `Node` are replaced with the values from the event. Example: `inc_86335482_bluecompute-web-app`
    
    ![SelectChannelName](NOI_slack_channel_created.png?raw=true) 

5. Select the `Slack->InviteToSlack` on the same event to invite a person to collaborate in the new channel.

6. Enter the name of the slack user (yet internal id) into the prompt and click `Run` button to invite.
 