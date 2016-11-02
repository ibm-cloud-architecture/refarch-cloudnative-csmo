# A Sample Tools Implementation of Incident Management Solution


  Authors: 	

		Arundhati Bhowmick (aruna1@us.ibm.com)
			
		Detlef Kleinfelder (detlef.kleinfelder@de.ibm.com)


The tools in the Incident Management solution are implemented to provide an end-to-end view of application. You may choose to use multiple tools to handle different functionality of the application. The below picture shows multiple tools that manages cloud native as well as hybrid application.

![CSMO Incident Management Implementation](../static/imgs/Cloud_Service_Management_Incident_Mgmt_with_Tools.png?raw=true)  

## Reference Tools Mapping 

There are various ways to build the tool chain for an Incident Management solution. For this project we utilized the following set of tools to showcase end-to-end incident management of [BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative) application that is hybrid in nature.  


**Monitoring** - [New Relic](Monitoring/NewRelic/NewRelic.md) for resource monitoring and E2E monitoring of URLs <and IBM Bluemix Application Management (BAM) for synthetic monitoring of the hybrid application and components.>

**Event Correlation** - [IBM Netcool Operations Insights](EventMgmt/NOI/NOI.md) to fulfill the event management and correlation activities.

**Notification** - [IBM Alert Notification](Notification/ANS/ANS.md) for notifying first responders on call via their preferred notification mean.

**Collaboration** - [Slack](Collaboration/Slack/Slack.md) for collaborating on the incidents with various personas of the resolution process.


**Dashboard** - [Grafana](Dashboarding/Grafana/README.md) to display an overall status of the _BlueCompute_ business service with key performance metrics, allowing to drill down into detailed pages or launch additionals details of the other tools of the toolchain like New Relic and NOI.


## Understanding System Context Flows for the Tools in CSMO Toolchain Connecting BlueCompute Application

Here is the view to system context of each these tools to give you deeper and broader perspective of the flow and integration.


### System Context Flow for New Relic

![System Context Flow New Relic](../static/imgs/Monitoring/NewRelic/Cloud_Service_Management-NewRelic_Hybrid.png?raw=true)

The above figure shows the deep dive of New Relic Ressource Monitoring and its various components and various integrated tools for incident management and their interactions. 

1.	New Relic offers the instrumentation of BlueCompute components like Node.js applications, nginx webserver/loadbalancers, java microservices and mysql databases and allows monitoring of key performance indicators for those ressources. It detects also Bluemix services used by various Bluemix applications. Both Public and SoftLayer instances are monitored. In Bluemix we will find native clound foundry applications as well as docker containers. 

2.	The data will be transferred to New Relic management system which is accessible with the UI and API calls.

3.	If thresholds are exceeded based on defined alert policy settings one or more alerting channels can be used to forward identified incidents.

4.	These channels actually forward the incident to external event correlation, notification or emailing systems. In this scenario we are using NOI for event correlation and New Relic forwards its events to a Netcool Omnibus message bus probe via a WebHook channel. 

5. The New Relic Rest API allows to query the data from external tools like Dashboarding solution. In this scenario Grafana runtime polls the New Relic data via the Rest API continously to display status and key performance metrics.


<!--- ### System Context Flow for BAM 

![System Context Flow BAM](../static/imgs/???.png?raw=true)

The above figure shows the deep dive of IBM Bluemix Application Monitoring (BAM) and its various components and various integrated tools for incident management and their interactions. BAM monitors the status Bluemix application in two ways.

1.	BAM will check base application URLs and also run Rest get/post calls against the BlueCompute Rest APIs.

2.	Secondly we can record synthetic web transaction scripts with the Selennium IDE browser plugin, upload them into BAM and playback those scripts from different data centers around the world.

3.	Both checks will provide status information and response time of the application components and sampled transaction use cases.

4.	Based on threshold settings violations in terms of availability or performance can be reported to the IBM Alert Notification System (ANS) Bluemix Service.

5.	ANS then will also forward these incidents to an external event correlation system via email. In this scenario we are using NOI as event correlation system.
--->


### System Context Flow for IBM Netcool Operations Insights (NOI)

![System Context Flow NOI](../static/imgs/Eventing/NOI/Cloud_Service_Management-NOI_Hybrid.png?raw=true)

The above figure shows the deep dive of NOI and its various components and various integrated tools for incident management and their interactions. One of the key takeaways from the diagram is that the solution supports a heterogeneous mixture of products and solutions, each feeding or being fed by the central NOI solution.

The following flow describes the setup and operations of this solution in an overall cloud service management space:

1.	BlueCompute application components & infrastructure are monitored by 3rd party solution New Relic for resource monitoring and URL response <and IBM BAM for synthetic monitoring (via ANS)>.

2.	The probes normalize the events into a common format and send them to the central Omnibus system. The monitoring events sent to NOI via these probes are then correlated, de-duplicated, analyzed & enriched. Further actions may be automated or performed by a first responder/incident owner/runbook automated service. 

3.	Impact has three roles: 

    + It extracts events from the BlueMix infrastructure and forwards events on to the collaboration and notification solutions. 
    + The analytics component of NOI enriches the events and finds correlations between events based on seasonality or relationship, limiting the number of alarms forwarded and making sure that important issues are prioritized. 
    + Impact also enriches technical events with organizational and environmental context information like deployment location, service relationships or affected client. Here a MySQL configuration data source is leveraged.
    
    The dashboards are used both to display events and allow manually forwarding of events if an operator decides to do so.  

4.	The correlated events are forwarded to collaboration and notification tools. Action may be performed to solve the issues detected. NOI supports a variety of such solutions and in this document we will look at integration with Slack for collaboration and IBM Alert Notification System for notification and escalation. NOI can publish events to generic targets (i.e. a single Slack channel which is used for all alerts) or specific ones (i.e. NOI will be automated to create a dedicated Slack channel for a single generated event ). 

5. Runbooks connected to NOI are automated to update the event status based on the resolution of the issue. The status updates can also be manually handled within NOI. It also has capability to have bi-directional communication with notification tool so that event status update can take place in either tool. This updated status is then propagated.


### System Context Flow for IBM Alert Notification System

![System Context Flow Grafana](../static/imgs/Notification/ANS/Cloud_Service_Management-AlertNotification_Hybrid.png?raw=true)

The above figure shows the deep dive of ANS and its various components and various integrated tools for incident management and their interactions. 

1. An alert is raised via NOI or the POST API and sent to the Alert Notification Service (API).
 
2. Alert Notification process the alerts via Notification Policies and delivers the alert as specified in the policy (Email, SMS, Slack or Voice)

3. Alert is delivered via one or more options, email, SMS, Slack or Voice to external targets.

4. First Responder, Development and the Incident owner use Collaboration tools for alert resolution.


### System Context Flow for Grafana

![System Context Flow Grafana](../static/imgs/Dashboarding/Grafana/Cloud_Service_Management-Grafana_Hybrid.png?raw=true)

The above figure shows the deep dive of Grafana and its various components and various integrated tools for incident management and their interactions. 

1. The Dashboard relies on data from various data sources which are accessed via various interfaces. 

    + The configuration management data is read from the database with the help of sql client tools. 
    + Status and key performance metrics from New Relic APM system is collected via the Rest APIs. 
    + Event information is read from the Netcool Omnibus system by means of a Rest API. 
    + Status and configuration information for Bluemix applications and containers are also retrieved view the Bluemix API/CLI. 

    Data can be accessed either directly from the Dashboard Rest API data provider or from a separate runtime instance.

2.	A Perl Runtime collects on a regular scheduled basis data from various data sources which provide monitoring and status information for the BlueCompute application. In this scenario this includes 
    + the ressource monitoring data from New Relic via a Rest API, 
    + the Bluemix Cloud Foundry information for applications and containers via the CF API,  
    + the NOI status information via the Netcool Rest API and 
    + the configuration data from the configuration database data source on MySQL to read and enrich the monitoring data with environment context data like deployment location and service-relationships.
    <and the synthetic monitoring results from BAM via a Rest API>
    
3. The perl runtime mashes up all relevant data and writes the consolidated data into the Grafana database based on InfluxDB.

4.	Grafana accesses the data via its defined data sources and displays the mashed-up data from the InfluxDB and individual New Relic data inside the configured dashboard pages.
Grafana allows also the launch of external URL pages in new browser tabs as part of the use case scenarios. This includes the launch of 

    + the event viewer page from NOI displaying events in context of a page item displaying the associated events via an ad-hoc filter for the selected item
    + the _BlueCompute_ Service Map from New Relic
<the LogMet logfile search page in context of a page item filled with the appropriate search query for the selected item>.

5.Via the event viewer the Runbook Automation can be triggered and displayed.




## How to Use the toolchain
 
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

For detailed steps please continue with [How to setup New Relic for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/blob/master/doc/Monitoring/NewRelic/NewRelic.md)

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
Grafana is one of the leading tools for querying and visualizing time series and metrics. In this project we used it to create dashboards for First Responder persona. Grafana features a variety of panels, including fully featured graph panels with rich visualization options. There is built in support for many of the time series data sources like InfluxDB or Graphite. We used InfluxDB - a time series database for metrics as a data source for Grafana and perl script to collect data from various APIs of BlueCompute CSMO infrastructure like New Relic, Bluemix, NOI or CMDB. 

For detailed steps please continue with [How to setup Grafana for BlueCompute](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/tree/master/doc/Dashboarding/Grafana/README.md)


## Reference Product Links

[IBM Netcool Operations Insights](http://www-03.ibm.com/software/products/en/netcool-operations-insight)

[IBM Alert Notification](http://www-03.ibm.com/software/products/en/ibm-alert-notification)
 
[New Relic](https://newrelic.com/) 

[Slack](https://slack.com)

[Grafana](http://grafana.org)
