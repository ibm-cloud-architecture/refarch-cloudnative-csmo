# Netcool Operations Insight event management for Hybrid application

(In Progress....)

IBM Netcool Operations Insight accelerates the operations management lifecycle from problem detection to fix. It receives event from ressource monitoring solutions, enriches, correlates and escalates events based on rule automation.

![System Context Flow](NOI system context flow.png?raw=true)  

In this document you will understand how to setup IBM Netcool® Operations Insight (NOI) in the middle of the service management tool chain and demonstrate the interaction of NOI with the other tool chain components of the toolchain.

Note: We will not cover standard installation and operation of NOI, since this is not unique to the Bluemix environment, but we will links to references. 
We will also link to the guide [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight) for details about the integration with Bluemix.



Netcool Operations Insight is operated though a web based GUI called DASH, login is https://{yourServer}:16311/ibm/console.



###Step 1: Install and Setup IBM Netcool Operations Insight

For base setup of an NOI instance, please follow the information of guide [Integrate Netcool Operations Insight into your Bluemix service management tool chain](https://developer.ibm.com/cloudarchitecture/docs/service-management/netcool-operations-insight)

###Step 2: Enable event reception for NewRelic incident send as webhooks


###Step 3: Install and Setup enrichment database 


###Step 4: Enrich events with enrichment database


###Step 5: Create View and Filter for BlueCompute


###Step 6: View application events for BlueCompute

Upon login you access the list of active events through the Incident -> Event Viewer menu.

The list of events displayed is controlled by a filter. You may, for example, wish to see only events related to a specific application or you may wish to see all the events which occurred in the last 10 minutes.

+ The filter "BlueCompute" displays all events for the BlueCompute business service based on the event field setting "Service=BlueCompute".
 
The format of the list is controlled by the View. 

+ The view "Case_Integrations" displays all events in a grouping form, where the first level is “ServiceName” and the second level “Location”.  
    
These fields have been enriched for each technical event coming from the monitoring sources based on a  configuration data source.

By this you can immediately see all affected services including the BlueCompute application and sub-grouped by location. 
In the following screenshot has two events with application components running on EU Bluemix region (bmx_eu-gb) and on Softlayer (SL).

![BlueCompute event in NOI](NOI events for bluecompute.png?raw=true)  

###Step 7: Forward critical events to alert notification system

