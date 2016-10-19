# Cloud Service Management and Operation for Hybrid application

## Architecture Overview
This project provides is a reference implementation for managing a BlueCompute Application that is hybrid in nature.
Cloud based applications need to be available all the time. Proper processes need to be put in place to assure availability and performance. This includes Incident and Problem management to respond to outages, but also Release Management to assure a seamless deployment and release of new versions.

  The Logical Architecture for overall Cloud Service Management and Operations is shown in the picture below.
   ![CSMO Architecture](static/imgs/Cloud_Service_Management_Incident_Mgmt_Overview-v2.png?raw=true)  

For more details on this reference architecture visit the [Architecture Center for Service Management](https://developer.ibm.com/architecture/serviceManagement)

## Incident Management Architecture Overview

Incident management and its operations are key to cloud service management. Incident management is optimized to restore the normal service operations as quickly as, thus ensuring the best possible levels of service quality and availability are maintained. Following figure provides deep dive into Incident Management 
![CSMO Incident Management Architecture](static/imgs/Cloud_Service_Management_Incident_Management-03.png?raw=true)  

For more details on this reference architecture visit the [Architecture Center for Incident Management](https://developer.ibm.com/architecture/gallery/incidentManagement)

### Reference Tools Mapping
For this project we utilized a reference set of tools to showcase end-to-end incident management.

**Monitoring** - uses [NewRelic](https://newrelic.com/) for resource monitoring and IBM Bluemix Application Management (BAM) for synthetic monitoring of the hybrid application and components.

**Event Correlation** - use the [IBM Netcool Operations Insights](http://www-03.ibm.com/software/products/en/netcool-operations-insight) to fulfill the event management and correlation activities.

**Notification** - uses [IBM Alert Notification](http://www-03.ibm.com/software/products/en/ibm-alert-notification)

**Dashboard** - uses open source [Grafana](http://grafana.org/)



