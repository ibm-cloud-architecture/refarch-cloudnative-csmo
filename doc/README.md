# A Sample Tools Implementation of Incident Management Solution

The tools in the Incident Management solution are implemented to provide an end-to-end view of application. You may choose to use multiple tools to handle different functionality of the application. The below picture shows multiple tools that manages cloud native as well as hybrid application.

![CSMO Incident Management Implementation](static/imgs/Cloud_Service_Management-Incident_Management_with_Tools.png?raw=true)  

### Reference Tools Mapping 
For this project we utilized a reference set of tools to showcase end-to-end incident management.

**Monitoring** - uses [NewRelic](https://newrelic.com/) for resource monitoring and E2E monitoring of URLs <and IBM Bluemix Application Management (BAM) for synthetic monitoring of the hybrid application and components.>

**Event Correlation** - uses the [IBM Netcool Operations Insights](http://www-03.ibm.com/software/products/en/netcool-operations-insight) to fulfill the event management and correlation activities.

**Notification** - uses [IBM Alert Notification](http://www-03.ibm.com/software/products/en/ibm-alert-notification)

**Collaboration** - uses [Slack](https://slack.com)

**Dashboard** - uses open source [Grafana](http://grafana.org)

### Understanding System Context Flows for the Tools in CSMO Toolchain Connecting BlueCompute Application


#### System Context Flow for New Relic

<![System Context Flow NewRelic](static/imgs/???.png?raw=true)>

The above figure shows the deep dive of NewRelic Ressource Monitoring and its various components and various integrated tools for incident management and their interactions. 

1.	NewRelic offers the instrumenation of BlueCompute components like Node.js applications, nginx webserver/loadbalancers, java microservices and mysql databases and allows monitoring of key performance indicators for those ressources. It detects also Bluemix services used by various Bluemix applications. Both Public and SoftLayer instances are monitored. In Bluemix we will find native clound foundry applications as well as docker containers. 

2.	The data will be transferred to NewRelic management system which is accessible with the UI and API calls.

3.	If thresholds are exceeded based on defined alert policy settings one or more alerting channels can be used.

4.	These channels actually forward the incident to external event correlation and/or a Dashboard solutions. In this scenario we are using NOI for event correlation and NewRelic forwards its events to a Netcool Omnibus message bus probe via a WebHook channel. 


<!--- #### System Context Flow for BAM 

![System Context Flow BAM](static/imgs/???.png?raw=true)

The above figure shows the deep dive of IBM Bluemix Application Monitoring (BAM) and its various components and various integrated tools for incident management and their interactions. BAM monitors the status Bluemix application in two ways.

1.	BAM will check base application URLs and also run Rest get/post calls against the BlueCompute Rest APIs.

2.	Secondly we can record synthetic web transaction scripts with the Selennium IDE browser plugin, upload them into BAM and playback those scripts from different data centers around the world.

3.	Both checks will provide status information and response time of the application components and sampled transaction use cases.

4.	Based on threshold settings violations in terms of availability or performance can be reported to the IBM Alert Notification System (ANS) Bluemix Service.

5.	ANS then will also forward these incidents to an external event correlation system via email. In this scenario we are using NOI as event correlation system.
--->


#### System Context Flow for IBM Netcool Operations Insights (NOI)

<![System Context Flow NOI](static/imgs/???.png?raw=true)>

The above figure shows the deep dive of NOI and its various components and various integrated tools for incident management and their interactions. One of the key takeaways from the diagram is that the solution supports a heterogeneous mixture of products and solutions, each feeding or being fed by the central NOI solution.

The following flow describes the setup and operations of this solution in an overall cloud service management space:

1.	BlueCompute application components & infrastructure are monitored by 3rd party solution NewRelic for resource monitoring and URL response <and IBM BAM for synthetic monitoring (via ANS)>.

2.	The probes normalize the events into a common format and send them to the central Omnibus system. The monitoring events sent to NOI via these probes are then correlated, de-duplicated, analyzed & enriched. Further action may be automated or performed by an first responder/incident Owner/runbook automated service. 

3.	Impact has two roles. It extracts events from the BlueMix infrastructure and forwards events on to the collaboration and notification solutions. The analytics component of NOI enriches the events and finds correlations between events, limiting the number of alarms forwarded and making sure that important issues are prioritized. The dashboards are used both to display events and manually forward them if an operator decides to do so. Impact also enriches technical events with organizational and environmental context information like deployment location, service relationships or affected client. Here a MySQL configuration data source is leveraged.

4.	The correlated events are forwarded to collaboration and notification tools. Action may be performed to solve the issues detected. NOI supports a variety of such solutions and in this document we will look at integration with Slack for collaboration and IBM Alert Notification System Duty for notification and escalation. NOI can publish events to generic targets (i.e. a single Slack channel which is used for all alerts) or specific ones (i.e. NOI will be automated to create a dedicated Slack channel for a single generated event ). 

5. Runbooks connected to NOI are automated to update the event status based on the resolution of the issue. The status updates can also be manually handled within NOI. It also has capability to have bi-directional communication with notification tool so that event status update can take place in either tool. This updated status is then propagated.

#### System Context Flow for IBM Alert Notification System

<![System Context Flow Grafana](static/imgs/???.png?raw=true)>

The above figure shows the deep dive of ANS and its various components and various integrated tools for incident management and their interactions. 

1.	to be done


#### System Context Flow for Grafana

<![System Context Flow Grafana](static/imgs/???.png?raw=true)>

The above figure shows the deep dive of Grafana and its various components and various integrated tools for incident management and their interactions. 

1.	A Perl Runtime collects on a regular scheduled basis data from various data sources which provide monitoring and status information for the BlueCompute application. In this scenario this includes the ressource monitoring data from NewRelic via a Rest API, the Bluemix Cloud Foundry information for applications and containers via the CF API and the NOI status information via the Netcool Rest API <and the synthetic monitoring results from BAM via a Rest API>.

2.	Perl runtime also accesses a configuration data source on MySQL to read and enrich the monitoring data with environment context data like deployment location and service-relationships.

3.	The perl runtime mashes up all relevant data and writes the consolidated data into the Grafana database based on InfluxDB.

4.	Grafana accesses the data via its defined data sources and displays the InfluxDB data inside the configured dashboard pages.

5.	Grafana allows the launch of the event viewer page from NOI displaying events in context of a page item<as well as the launch og LogMet logfile search page in context of a page item>.


### How to Use the toolchain
 
The following walkthrough guides you through how to use the toolchain for end-to-end monitoring of the hybrid application. You will learn how to implement basic incident management capabilities and how to build a more advanced, robust incident management solution.

###Step 1: Installation prerequisites

When deployed using an instant runtime, the solution for incident management requires the following items:

  +  IBM Bluemix account
  +  A hybrid application - [BlueCompute application set up instruction](https://github.com/ibm-cloud-architecture/refarch-cloudnative)
    
###Step 2: Incident Management walkthrough

The cloud native Cloud Service Management and Operations [incident management walkthrough](https://developer.ibm.com/architecture/gallery/incidentManagement/walkthrough/Introduction) is provided with the tools in the toolchain.


The following sections only focusses on updates needed to instrument or use a hybrid application and will defer to the published how-to documents for the selected tools of the toolchain.

###Step 3: Monitoring

#### Tool option a: How to Use New Relic for BlueCompute

New Relic is a Software-as-a-Service (SaaS) offering, where agents are injected into Bluemix Runtimes,  IBM Bluemix Containers or SoftLayer Containers and automatically start reporting metrics back to the New Relic service over the internet.

Please be aware that the instrumented components will need an active internet out-bound connection either directly or via various Gateway services.

For detailed steps please continue with [How to setup NewRelic for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Monitoring/NewRelic/NewRelic.md)

<!--- ####Step 3b: How to Use for BAM for BlueCompute --->

### Step 4: Event Management

#### Tool option a: How to use IBM Netcool Operations Insight for BlueCompute

IBM Netcool Operations Insight accelerates the operations management lifecycle from problem detection to fix. It receives event from ressource monitoring solutions, enriches, correlates and escalates events based on rule automation.

For detailed steps please continue with [How to setup NOI for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/EventMgmt/NOI/NOI.md)

###Step 5: Notification

#### Tool option a: How to use IBM Alert Notification System for BlueCompute
IBM Alert Notification System is IBM Bluemix®	service environment that instantly	delivers notifications	of problem occurrences in your	Bluemix	environment	using automated email, Short Message Service (SMS), and voice	messaging.

For detailed steps please continue with [How to setup ANS for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Notification/ANS/ANS.md)

### Step 6: Collaboration

#### Tool option a: How to use Slack for BlueCompute
Slack is an instant messaging and collaboration system on steroids. Slack’s channels help you focus by enabling you to separate messages, discussions and notifications by purpose, department or topic. For incidents which occur in a BlueCompute environment, channels can be used to collobarate on the remediation of the incident with various users like the First Responder, Subject Matter experts, Incident Owner as well as with a numerous number of tools via prebuild integrations.

For detailed steps please continue with [How to setup Slack for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Collaboration/Slack/Slack.md)

### Step 7: Dashboarding

#### Tool option a: How to use Grafana Dashboarding for BlueCompute
Grafana is one of the leading tools for querying and visualizing time series and metrics. In this project we used it to create dashboards for First Responder persona. Grafana features a variety of panels, including fully featured graph panels with rich visualization options. There is built in support for many of the time series data sources like InfluxDB or Graphite. We used InfluxDB - a time series database for metrics as a data source for Grafana and perl script to collect data from various APIs of BlueCompute CSMO infrastructure like NewRelic, Bluemix, NOI or CMDB. 

For detailed steps please continue with [How to setup Grafana for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/tree/master/doc/Dashboarding/Grafana/README.md)


