#  How-to Guide for the Build to Manage Health Check API 
 

  Authors: 	
			
	  Dave Thompson	 (dthmpson@us.ibm.com)
	  IBM Cloud Client Adoption and Technical Enablement

		
## Introduction
The initial implementation of the health check API provides an example of adding a REST API health check method to a microservice. 
The microservice used for this example is the StoreWebApp component of the IBM BlueCompute Store application, which provides the application's web front end for browsers.
The following diagram shows the reference architecture used by the BlueCompute Store application.

<img src="BlueComputeStore.png" width="1000">

The requirements for the health check API were derived from the CSMO Build to Manage PoV document, and the implementation is based on the Broadly node-healthchecks module. 

The example health check API provides checks for resources that can be referenced as URLs:
* The existence and reachability of web pages provided by the application.
* The existence and reachability of local files used by the application.
* The existence and reachability of downstream resources required by the application.
* Text content that is expected to be returned when these resources are accessed can also be checked for.

This example health check API does not currently check things like running processes or system resource utilization.

The health check API can be called by monitoring applications such as BAM as a REST API type test. 
First responders can navigate to the URL of the health check API based on information contained in email or Slack notifications.



## Requirements
The Build to Manage PoV document states: 

*A HealthCheck API is, at minimum, a separate REST service implemented within a microservice component that quickly returns the operational status of the service and an indication of its ability to connect to downstream dependent services.  A HealthCheck API can also include performance information (such as component execution times or downstream service connection times) as part of the returned service status.* 
... 
*Depending on the deemed state of the dependencies, an appropriate HTTP return code and JSON object should be returned.*

The derived requirements are:
* The health check API should be a REST service within the microservice component.
* The health check API should return the operational status of the component and its ability to connect with downstream components that it depends on.
* The health check API can also return performance information such as connection times.
* The results should be returned as an HTTP status code plus JSON data.

## Related use case
The use case that this health check API supports is:

*How a First Responder receives a health alert for a Bluemix application or microservice and opens the health API URL to verify the current status (SLA - within 1 min)*


## Health Check API implementation
The StoreWebApp component is written using node.js, so the health check API also written using node.js.

The Broadly node-healthchecks module was adapted to meet the health check API requirements rather than writing a health check implementation from scratch. 
See the Broadly node-healthchecks repository for more details:  https://github.com/broadly/node-healthchecks.

The changes that were needed were:
* Adding an option to return JSON content instead of HTTP content.
* Modifying the internal data stored for each individual check to allow the "expected text" checked for to be returned.
* Removing the potentially verbose response body data from the data for each individual check prior to returning that data in JSON format.

## Data that is returned
The following images show the original HTML data returned and the data returned using the option to return JSON content:

**Default HTML output**

![Original HTML output](DefaultOutput.png?raw=true)

**JSON output**

![JSON output](jsonOutput.png?raw=true)


## Configuring the checks to be made
The healthchecks module checks URLs that are listed in a **checks file**. The URLs are relative to the server on which the app is deployed. The URLS can use an absolute pathname, or can include a protocol and hostname.
The URLs can point to web pages, or to files.  Each entry in the checks file can contain **expected text**, where the expected text is text content that is expected to be returned in the response body when accessing the URL.

A response timeout threshold that applies to each check can be specified when configuring the module; the default is 3 seconds.

The checks file is maintained and distributed as part of the microservice that it instruments, and the microservice currently must be re-started to pick up changes made to the checks file.

The details and use of the checks file are unchanged from the Broadly node-healthchecks module; for complete details see https://github.com/broadly/node-healthchecks.

**An example checks file is shown here:** 

    # Check the main website, including text content
    /	IBM Cloud Architecture

    #Check the Inventory page
    /inventory/

    # Check for stylesheets and for text content in stylesheets
    /stylesheets/font-awesome/font-awesome.css    @font-face


    # Check scripts or for text content in scripts
    # This line will cause a failure result since the script does not exist
    #/scripts/myscript           use strict

    # Check a sub-domain
    # Not currently used, for example purposes only
    #//some-subdomain.some-site.com/reviews Review Data

    # Check HTTP access, including checking for text content
    http://localhost:8000	BlueCompute Store!
    http://localhost:8000/inventory/	Dayton Meat Chopper
    
## Results of checks
If all checks pass, an HTTP status code of 200 is returned by the API call.

If any checks fail, an HTTP status code of 500 is returned.

Internally to the healthchecks module, the following data is kept for each check:
* The URL that was checked.
* The response time for the check (if the check did not time out).
* The HTTP status code returned when attempting to access the URL.
* The expected text (if any) that was check for.
* The response body if one was returned.
* For failed checks, a **reason** string that identifies what aspect of the check failed.

This is an example of the formatted JSON data returned for a failed check:

![Formatted JSON output](jsonOutputDetail.png?raw=true)

## Code changes to the Broadly node-healthchecks module
* Added a field to the outcome object for checks in order to be able to return the expected text value.
* Added a simple function to remove the response body property from outcome objects prior to returning them as JSON.
* Added logic to process the new option to return data in JSON format.
* Added an if / else block to return a response with JSON content instead of HTML content.

## Adding the healthchecks module to the StoreWebApp component
Since the modified healthchecks module is not available from npm, the healthchecks.js file must be added to the StoreWebApp project.

* Add a directory and copy the modified healthchecks.js file and the unmodified index.hbs file required by healthchecks.js into the directory.
	* These files could be placed in an existing project directory depending upon your project layout preferences.
* Create a checks file and add it to the project.
	* Add the checks file to the root of the project or to the config directory depending upon your project layout preferences.
* Edit package.json to add the healthcheck.js dependencies **handlebars** and **pretty-hrtime**.
	* `"handlebars": "^4.0.6"`
	* `"pretty-hrtime": "^1.0.3"`
* Edit app.js
	* Load healthchecks.js module from the local directory.
		* For example: `const healthchecks = require('./lib/healthchecks');`
	* Set up a variable to point to the checks file.
		* For example: `const CHECKS_FILE = __dirname + '/checks';`
* Create an options object to pass in when adding the healthchecks middleware.
	* Include the option to return JSON, in addition to the checks file and an optional timeout.
		* for example: ```const options = {
          filename:   CHECKS_FILE, 
          timeout:    '5s', 
          returnJSON:	true
        };```
* Add the healthchecks middleware layer to Express, for example:
	* `app.use('/_healthchecks', healthchecks(options));`

After starting the StoreWebApp component, the health check API can be accessed at the base URL for the app + /_healthchecks, for instance https://bluecompute-web-app-your-instance.mybluemix.net/_healthchecks.

An example of a project with the healthchecks module added is shown here:


![Project with healthchecks added](app_js.png?raw=true)


## Calling the health check API from BAM
Adding the health check API as a monitoring test is done just like adding any other REST API test to BAM.

* Add a new test from the monitoring tab for your instance of the StoreWebApp app deployed in Bluemix.
* Select a **Single Action** type test.
* In the Single Action setup panel, select the **REST API** option.
* Provide a meaningful name and description.
* Use the **GET** method, and supply the URL for the health check API.
* This will be the base URL of your app plus **/_healthchecks**.
	* For instance: `https://bluecompute-web-app-your-instance.mybluemix.net/_healthchecks`

## Sending Notifications
You can send notifications for BAM alerts due to failed health check tests by setting up a notification policy in ANS. The process is the same as for setting up a notification policy for any other test.
Depending on the configuration of your ANS system, you can send notifications to NOI and Slack as well as via email. For NOI and Slack a gateway may be required, and is outside of the scope of this how-to guide.

In the case of Slack notification, a channel is created for the alert, and essential personnel can be auto-invited

**Example email notification content:**

![Email notification part 1](email_notify1.png?raw=true)

![Email notification part 21](email_notify2.png?raw=true)

**Example Slack notification content:**

![Slack notification ](slack_notify.png?raw=true)


