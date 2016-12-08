#  How to Guide forIBM Bluemix Availability Monitoring 
 

  Authors: 	
			
	  Ray Stoner	 (rstoner@us.ibm.com)
	  Senior Managing Consultant
	  IBM Cloud
	  Client Technical Engagement Lab Services

		
## Introduction
IBM Bluemix Availability Monitoring (BAM) is an IBM Bluemix service that monitors the performance and availability of your Bluemix applications. This service provides the following test facilities for your application
    + URL monitoring for availability and response time
    + API tests for availability and response time
    + Simulated performance tests using Selenium scripts

This document shows you how to set up and leverage BAM in a Public Bluemix account. 
The Scripts and tests are run in IBM supplied Points of Presence or POPS. There are 15 globally located POPS available.  
## BAM System Context
![BAM Context Diagram](BAMContext.png?raw=true)
1.	Deployed applications
2.	BAM monitors URLS, APIs and runs Selenium scripts
3.	Alerts raised by BAM either via thresholds or failed tests are forwarded to ANS
4.	ANS forwards the alerts via email to NOI. 
5.	NOI manages the alerts and determines notification routes

## BAM IS IN THE BLUEMIX FABRIC
Availability Monitoring is available as part of the BlueMix fabric and as a service in the DevOps domain in the Bluemix catalog. Two plans are available a Lite plan (Up to 3 Million Data Points/month) or Unlimited (PayGo) @$3.25 per Million Data Points/month.
As you add applications to your Bluemix organizations page, the associated URL or route is automatically monitored by BAM for availability and load time of the applications launch page. The test is set up to these defaults:
    + Run Interval of 15 Minutes
    + Critical Threshold 10 Seconds (page load)
    + Warning Threshold 5 Seconds 
    You will need to change these thresholds to suite your needs. 



Below is a recently deployed application. Click on the application to view the run time configuration

![Select Application](BAMSelectAppscr1.png?raw=true)

![Select Monitoring Tab](BAMSelectMonitorinTab.png?raw=true)

You will arrive at the summary screen below, where you see
1.	Test Availability
2.	Number of Test running
3.	And the usage percentage of your BAM service. 
Click on View All Tests

![View all Tests](BAMViewAllTests.png?raw=true)

You will be taken to the Tests view:

![Test Summary](BAMtestSummary.png?raw=true)






To view/edit the test click on the action bar and select edit. Note you cam also stop, delete and start a test from this menu. 


