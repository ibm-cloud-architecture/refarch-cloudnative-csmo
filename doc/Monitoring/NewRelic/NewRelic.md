# New Relic Resource Monitoring for Hybrid Application

  Authors: 	
			
		Detlef Kleinfelder (detlef.kleinfelder@de.ibm.com)
		
		
New Relic is a Software-as-a-Service (SaaS) offering, where agents are injected into Bluemix Runtimes,  IBM Bluemix Containers or SoftLayer Containers and automatically start reporting metrics back to the New Relic service over the internet.

Please be aware that the instrumented components will need an active internet connection either directly or via various Gateway services.

New Relic is operated though a web based GUI, login is https://rpm.newrelic.com.


###Step 1: Get a New Relic account
You will need to get a licence for New Relic in order to manage the _BlueCompute_ components accordingly.

See [How to New Relic on Bluemix](https://developer.ibm.com/cloudarchitecture/docs/service-management/new-relic-bluemix-application)

###Step 2: BlueCompute Instrumentation
New Relic code instrumentation has been added to the supported _BlueCompute_ components which includes:
  + node.js,
  + java microservices
  + nginx web server
  + mysql sqlnodes 

The covered environment for the _BlueCompute_ application is described in the following table:

| Component                     | New Relic agent |
|:------------------------------|----------------|
| nginx web server LB           | nginx plugin   |
| bluecompute web app           | node.js agent  |
| inventory bff app             | node.js agent  |
| socialreview bff app          | node.js agent  |
| API Connect service           | Not available  |
| social review microservice    | java agent     |
| inventory microservice        | java agent     |
| netflix eureka                | java agent     |
| netflix zuul                  | java agent     |
| VPN service                   | Not available  |
| cloudant DB service           | Not available  |
| yyatta on SL                  | Not available  |
| mysql sql nodes               | mysql plugin   |
| mysql data nodes              | Not available  |

The agents are pre-installed with the GitHub code and will be activated during application start only if a valid New Relic license is provided. The mechanisms for activation are different based on the deployment type. 

+ Bluemix Cloud Foundry application

    For cloud foundry applications the configuration of the New Relic license is retrieved from a custom user provided service (cups) which shall be called New Relic. If the application does find the service and the settings for the license key during push, it will activate and start the agent automatically.

    This is true for the cloud foundry applications:

    + [BlueCompute Web Application](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web)
    
    + [Inventory BFF Application](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bff-inventory)
    
    + [SocialReview BFF Application](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bff-socialreview)
    
+ Bluemix Container application
    
    For the Bluemix based containers running _BlueCompute_ components the license key has to be added to the docker container during container start or creation of the bluemix   container group with the -e NEW_RELIC_LICENSE_KEY=your-license-key option, where “your-license-key” is your New Relic license key.
    
    Additionally you have to define the application name for the New Relic agent with the option -e CG_NAME=your-appname where “your-appname” is your  desried name for the application shown and used inside New Relic. If you want to deploy the application to different regions or spaces, adding a flag to the name will allow to manage the applications more easily. If the same name is used, New Relic will handle the application instances as a single application.

    This is true for the Bluemix containers:
    
    + [Inventory Microservice](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory)
    
        When creating the container group add the options for New Relic:
        
        `cf ic group create -p 8080 -m 512 --min 1 --auto --name micro-inventory-group -e NEW_RELIC_LICENSE_KEY=[YOUR_LICENSE_KEY] -e  "CG_NAME=microservice-inventory" -e "eureka.client.serviceUrl.defaultZone=https://eureka-cluster-dev.[YOUR_NAMESPACE]/eureka/" -e "spring.datasource.url=jdbc:mysql://[YOUR_MYSQL_IP1]:3306,[YOUR_MYSQL_IP2]:3306/inventorydb" -e "spring.datasource.username=[YOUR_DBUSER]" -e "spring.datasource.password=[YOUR_PASSWORD]" -n inventoryservice -d mybluemix.net registry.[YOUR REGION].bluemix.net/$(cf ic namespace get)/inventoryservice:cloudnative`
    
    + [Socialreview Microservice](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-socialreview	)
    
        When creating the container group add the options for New Relic: 
        
        `cf ic group create -p 8080 -m 512 --min 1 --auto --name micro-socialreview-group -e NEW_RELIC_LICENSE_KEY=[YOUR_LICENSE_KEY] -e  "CG_NAME=microservice-socialreview" -n socialreviewservice -d mybluemix.net registry.ng.bluemix.net/{yournamespace}/socialreviewservice`
    
    + [Netflix Zuul Edge Proxy](https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-zuul)
    
        When deploying the container group with the `deploy-container-group.sh` script, change the call in the script to

        `cf ic group create --name zuul_cluster \
          --publish 8080 --memory 256 --auto \
          --min 1 --max 3 --desired 1 \
          --hostname ${PROXY_HOSTNAME} \
          --domain ${ROUTES_DOMAIN} \
          --env NEW_RELIC_LICENSE_KEY=[YOUR_LICENSE_KEY] \
          --env CG_NAME=zuul-cluster \
          --env eureka.client.serviceUrl.defaultZone="${REGISTRY_URL}" \
          --env eureka.instance.hostname=${PROXY_HOSTNAME}.${ROUTES_DOMAIN} \
          --env eureka.instance.nonSecurePort=80 \
          --env eureka.instance.preferIpAddress=false \
          --env spring.cloud.client.hostname=${PROXY_HOSTNAME}.${ROUTES_DOMAIN} \
          ${BLUEMIX_REGISTRY_HOST}/${BLUEMIX_REGISTRY_NAMESPACE}/${PROXY_IMAGE}`
    
    + [Netflix Eureka Service Discovery](https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-eureka)
    
        When deploying the container group with the `deploy-container-group.sh` script, change the call in the script to
        
        `cf ic group create --name zuul_cluster \
         --publish 8080 --memory 256 --auto \
         --min 1 --max 3 --desired 1 \
         --hostname ${PROXY_HOSTNAME} \
         --domain ${ROUTES_DOMAIN} \
         --env NEW_RELIC_LICENSE_KEY=[YOUR_LICENSE_KEY] \
         --env CG_NAME=eureka-cluster \
         --env eureka.client.serviceUrl.defaultZone="${REGISTRY_URL}" \
         --env eureka.instance.hostname=${PROXY_HOSTNAME}.${ROUTES_DOMAIN} \
         --env eureka.instance.nonSecurePort=80 \
         --env eureka.instance.preferIpAddress=false \
         --env spring.cloud.client.hostname=${PROXY_HOSTNAME}.${ROUTES_DOMAIN} \
         ${BLUEMIX_REGISTRY_HOST}/${BLUEMIX_REGISTRY_NAMESPACE}/${PROXY_IMAGE} `


+ SoftLayer Container application

    For the softlayer based containers running _BlueCompute_ components the license key has to be added to the environment with a variable

    `export NEW_RELIC_LICENSE_KEY=your-license-key`

    where “your-license-key” is your New Relic license key. The subsequent setup scripts will capture the value and configure and start the New Relic Java Agent with the MySQL plugin as the SQL node containers are started.

    This is true for the Softlayer containers:
    
    + [MySQL Cluster](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency/tree/master/mysql-cluster)
    
###Step 3: Add notification channel to Netcool Operations Insight (NOI)

The Netcool Operations Insight (Omnibus) integration is done via webhook integration. There are yet two alert notification technologies for New Relic in place which will both needed.

Follow these steps to send alerts and notification to NOI. 

#### Step 3a: Setup the Alert (new) Notification channel
1. Select Alerts(New) from the top menu
2. Select `Alert notification channel` tab
3. Create a new notification channel by clicking on `New notification channel`
4. Select `WebHook` as the Channel Type
5. Input Webhook name (e.g. NOI)
6. Input Base URL of your NOI instance running the message bus probe. Please see [How to setup NOI for BlueCompute](http://to be added) for details about NOI and the message bus probe to receive events.
7. Finish with `Create Channel`

This channel can be used within the alerting policies which are described later on.

#### Step 3b: Setup the Alert (old) Notification channel
1. Select `APM` from the top menu
2. Select `Alerts` from the submenu
3. Select `Channel and groups` tab from the tree menu on the left
4. Create a new notification channel by clicking on `Create channel`
5. Select `WebHook` as the Channel Type from the drop-down list
6. Input Webhook name (e.g. NOI)
7. Input Webhook URL of your NOI instance running the message bus probe. Please see [How to setup NOI for BlueCompute](http://to be added) for details about NOI and the message bus probe to receive events.
8. Switch to `All critical events` from the Notification level drop down list   
9. Finish with `Integrate with webhooks`

This channel can be used within the alerting policies which are described later on.



### Step 4: Define key transactions
In order to defined key transaction which are most important for you in the _BlueCompute_ environment, you can specify those from the list of discovered transactions.
To create a key transaction follow the instructions on [https://docs.newrelic.com/docs/apm/transactions/key-transactions/creating-key-transactions](https://docs.newrelic.com/docs/apm/transactions/key-transactions/creating-key-transactions).

Key transactions can be defined for New Relic supported application types. We have defined one key transaction for each supported node.js and java microservice application of the 
s with an initial Apdex target value.The Apdex value is a industry standard metric for rating the user satisfaction. See [https://docs.newrelic.com/docs/apm/new-relic-apm/apdex/apdex-measuring-user-satisfaction](https://docs.newrelic.com/docs/apm/new-relic-apm/apdex/apdex-measuring-user-satisfaction) for more details on the definition and measurement. The 

| BlueCompute application component  | Key Transaction                    | Apdex |
|:-----------------------------------|:-----------------------------------|-------|
| bluecompute web app                | get%20/inventory                   | 0.45  |
| inventory bff app                  | get /api/items                     | 0.76  |
| socialreview bff app               | Get /reviews/list                  | 0.89  |
| social review microservice         | get /reviews/list                  | 0.89  |
| inventory microservice             | /inventory (GET)                   | 1.0   |
| netflix eureka                     | /${eureka.dashboard.path:/} (GET)  | 0.99  |
| netflix zuul                       | /dispatcherServlet                 | 1.0   |

### Step 5: Setup Alert Policies
When all components have been instrumented, you can start to setup alert policies for the components.
Log into New Relic UI with your account and chose “Alerts” and “Alert Polices” tab and select “Create alert policy” button:

Here you will create policies for the various component types. If you prefer you can also define a single policy with all alert conditions for all the components types). We are preferring separate polices for the ease of management allowing component specific thresholds. The following policy setup has been chosen:

- nginx instances
- node.js instances
- java instances
- mysql instance

Some recommended violation conditions for the policies are described in the following chapters. These might need to be adapted depending on the different workload configuration of the _BlueCompute_ instance.



#### Setup Alert (Old) Policy 

The older Alert Policies technology of New Relic allows to define the monitor of URLs for application availability/Downtime while the new ones yet do not support this. Therefore a old Policy type is needed at this stage.

#####  Alert (Old) Policy for Applications Availability


- Login into New Relic UI
- Select `APM -> Alerts` from the top menu bar (please do not use directly `Alerts` from the top menu).
- Select `Application policies` from the left menu tree.
- Create a new policy called `BlueCompute` by creating the `Create application policy` button, enter the name `BlueCompute` and select `Create` button.
- Enter 2 minutes for `Downtime Alert when any ping URL is unresponsive for x minutes` and select the chechbox to activate the settings.
- Click on the `Assign Application` button to select your application
- Select each application for this policy under step 1 `Select applications to move` by ticking the checkbox
      + eureka-cluster
      + zuul-cluster
      + inventory-bff-app
      + socialreview-bff-app
      + bluecompute-web-app
      + microservice-inventory
      + microservice-socialreview
- Choose `Move to BlueCompute` under step 2 `Choose destination`  
- Click the `Assign Application` button to add these applications to your policy
- For each application do
    + click on the `Ping URL icon` 
    + add the `URL to monitor` under the Availability URL section. Use the following URLs or adopt them if you use different routes.
 
        | Application                   | URL to monitor                                    |
        |:------------------------------|:--------------------------------------------------|
        | bluecompute-web- app          | https://bluecompute-web-app.eu-gb.mybluemix.net   |
        | eureka-cluster                | https://eureka-cluster-dev.eu-gb.mybluemix.net    |
        | zuul-cluster                  | https://zuul-cluster-dev.eu-gb.mybluemix.net/info |

    + Save settting with `Save your changes` button
- Switch to the `Alert Channels` tab
- Click on `Select channels` button
- Select `NOI` channel under the Webhooks section
- Click `Save now`


#### Setup Alert (new) Policies
By means of the new alert policies you can create also policies for plugins like MySQL.

##### Alert (New) Policy for Nginx

1. Create an alert policy (sample name: CSMO nginx policy )
2. Assign the nginx entities to the policy as desired
3. Define one or more threshold conditions

    | Condition name                         | Product    | Plugin type        | Condition                                                          | Threshold base |                                              
    |:---------------------------------------|------------|--------------------|--------------------------------------------------------------------|----------------|
    | Nginx Active client connections (High) | Plugins    | nginx web server   | Critical: Active client connections > 700 units for at least 5 mins | On 1024 worker connections and 1  worker process|
    | Nginx Connections drop rate (High)     | Plugins    | nginx web server   | Critical: Connections drop rate > 5 units for at least 5 mins ||

    For specific nginx entities separate policies can be setup to adopt individual load behavior for metrics like “response time”, “requests rate” or “accept rate”.

4. Switch to the tab `Notification channels`
5. Click on `Add notification channel`
6. Select the Webhooks folder
7. Select `NOI` from the available webhook channels
8. Click `Update policy` to finish
9. Click on `Incident preference`
10. Select `by incident and entity` to get an event for every violation.

##### Alert (New) Policy for node.js

1. Create an alert policy (sample name: CSMO node.js policy )
2. Assign the node.js entities to the policy as desired
3. Define one or more threshold conditions

    | Condition name                         | Product    | Plugin type        | Condition                                                          | Threshold base |                                              
    |:---------------------------------------|------------|--------------------|--------------------------------------------------------------------|----------------|
    | Node.js Apdex (Low)                    | APM        | Application Metric | Critical: Apdex < 0.8 for at least 5 mins                           |   https://docs.newrelic.com/docs/apm/new-relic-apm/apdex/apdex-measuring-user-satisfaction|
    | Node.js Error percentage (High)        | APM        | Application Metric | Critical: Error percentage > 5 % for at least 5 mins               ||
    | Node.js Key Transaction Apdex (Low)    | APM        | Application Metric | Critical: Apdex < 0.5 for at least 5 mins for key transaction “get%20/inventory” ||

    For specific node.js entities and key transactions separate policies can be setup to adopt individual load behavior for metrics like “response time”, “apdex”, “throughput” or “web transaction times”.

4. Switch to the tab `Notification channels`
5. Click on `Add notification channel`
6. Select the Webhooks folder
7. Select `NOI` from the available webhook channels
8. Click `Update policy` to finish
9. Click on `Incident preference`
10. Select `by incident and entity` to get an event for every violation.

##### Alert (New) Policy for java microservices

1. Create an alert policy (sample name: 	CSMO java  policy )
2. Assign the java microservice entities to the policy as desired
3. Define one or more conditions

    | Condition name                         | Product    | Plugin type        | Condition                                                          | Threshold base |                                              
    |:---------------------------------------|------------|--------------------|--------------------------------------------------------------------|----------------|
    | Java Apdex (Low)                       | APM        | Application Metric | Critical: Apdex < 0.8 for at least 5 mins           **               |https://docs.newrelic.com/docs/apm/new-relic-apm/apdex/apdex-measuring-user-satisfaction|
    | Java Error percentage (High)           | APM        | Application Metric | Critical: Error percentage > 5 % for at least 5 mins               ||


    For specific java entities and key transactions separate policies can be setup to adopt individual load behavior for metrics like “response time”, “apdex”, “throughput” or “web transaction times”.

4. Switch to the tab `Notification channels`
5. Click on `Add notification channel`
6. Select the Webhooks folder
7. Select `NOI` from the available webhook channels
8. Click `Update policy` to finish
9. Click on `Incident preference`
10. Select `by incident and entity` to get an event for every violation.
##### Alert (New) Policy for mysql sqlnodes

1. Create an alert policy (sample name: 	CSMO mysql policy )
2. Assign the mysql entities to the policy as desired
3. Define one or more conditions

    | Condition name                         | Product    | Plugin type        | Condition                                                          | Threshold base |                                              
    |:---------------------------------------|------------|--------------------|--------------------------------------------------------------------|----------------|
    | Mysql Connections (Low)                | Plugins    | Mysql              | Critical: Connections < 1 unit for at least 120 mins               | One connection is always expected|
    | Mysql Connections (High)               | Plugins    | Mysql              | Critical: Connections > 120 units for at least 5 mins              | Default maximum connections are 151|


    For specific MySQL entities separate policies can be setup to adopt individual load behavior for metrics like “reads/sec”, write/sec” and “connections”.

4. Switch to the tab `Notification channels`
5. Click on `Add notification channel`
6. Select the Webhooks folder
7. Select `NOI` from the available webhook channels
8. Click `Update policy` to finish
9. Click on `Incident preference`
10. Select `by incident and entity` to get an event for every violation.

### Step 6: Configure Service MAP
For _BlueCompute_ you can create a service map containing all the instrumented components.
See details see [https://docs.newrelic.com/docs/data-analysis/service-maps/get-started/customize-your-service-maps](https://docs.newrelic.com/docs/data-analysis/service-maps/get-started/customize-your-service-maps	)
	
For a _BlueCompute_ service map do:

- Login into New Relic UI
- Select “APM” and “Service maps” and “Map List”  from the menu bars
- Select “Create new map”
    1. Select the “application” button and
        - Select the application components from _BlueCompute_ and add them to the map by clicking the “+” sign
            + eureka-cluster
            + zuul-cluster
            + inventory-bff-app
            + socialreview-bff-app
            + bluecompute-web-app
            + microservice inventory
            + microservice socialreview
    2. Now switch to the “plugins” components by selecting the plugins button 
        - Select the nginx seb server list and add your nginx instance to the map by clicking the “+” sign
        - Go back to the plugin list, select now the mysql list and add you mysql instances to the map by clicking the “+” sign
    3. Most connections are between components are created automatically.If links are missing you can create links manually by:
        - Select the pencil icon of a node.
        - Select the arrow icon for either inbound or outbound connection
        - Select the green plus sign of another node which you want to connected
    4. If node are missing which should be displayed as well-defined, you can create custom nodes by
        - Click on the “create custom node” snowflake icon
        - Assign it a name (e.g. VPN service to the Softlayer datacenter) and create links as appropriate to other nodes (see before)
    5. If nodes are clustered you can group them by drag and drop on each other and assign a group name (e.g. two mysql sqlnodes are building the mysql cluster used by the inventory microservice)
    6. Arrange the nodes by moving them on the pane
- Finish the map with the “Save” button

A final service map can look like this:
![BlueCompute Service Map in New Relic](NR service map.png?raw=true)  





