# Cloud Service Management and Operation for Hybrid application


  Authors: 	

		Arundhati Bhowmick (aruna1@us.ibm.com)

		Ingo Averdunk ( averdunk@de.ibm.com)
		

## Architecture Overview
This project provides is a reference implementation for managing a BlueCompute Application that is hybrid in nature.
Cloud based applications need to be available all the time. Proper processes need to be put in place to assure availability and performance. This includes Incident and Problem management to respond to outages, but also Release Management to assure a seamless deployment and release of new versions.

  The Logical Architecture for overall Cloud Service Management and Operations is shown in the picture below.
   ![CSMO Architecture](static/imgs/Cloud_Service_Management_Overview.png?raw=true)  

For more details on this reference architecture visit the [Architecture Center for Service Management](https://www.ibm.com/devops/method/content/architecture/serviceManagementArchitecture)

## Incident Management Architecture Overview

Incident management and its operations are key to cloud service management. Incident management is optimized to restore the normal service operations as quickly as, thus ensuring the best possible levels of service quality and availability are maintained. Following figure provides deep dive into Incident Management 
![CSMO Incident Management Architecture](static/imgs/Cloud_Service_Management-Incident_Management_v2.png?raw=true)  

For more details on this reference architecture visit the [Architecture Center for Incident Management](https://www.ibm.com/devops/method/content/architecture/serviceManagementArchitecture#0_1)

## Problem Management Architecture Overview

Problem management aims to resolve the root causes of incidents to minimize the adverse impact of incidents caused by errors, and to prevent the recurrence of incidents related to these errors. Capabilities include root cause analysis, incident analysis, and aspects of incident management.
![CSMO Problem Management Architecture](static/imgs/Cloud_Service_Management_Cloud_Problem_Management.png?raw=true)  

For more details on this reference architecture visit the [Architecture Center for Problem Management](https://www.ibm.com/devops/method/content/architecture/serviceManagementArchitecture#0_2)


# Sample Tools Implementation

Tools for Cloud Service Management and Operation may be implemented in various ways.
See sample [Tools Implementation Guide](doc/Incident_Management_Implementation.md) of Incident Management solution for a hybrid application.


 


