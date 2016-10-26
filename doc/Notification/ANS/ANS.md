# IBM Alert Notification System notification for Hybrid application

It is IBM Bluemix®	service environment that instantly	delivers notifications	of problem occurrences in your	Bluemix	environment	using automated email, Short Message Service (SMS), and voice	messaging.
IBM Alert Notification System allows you to 

+ Define groups	so alerts are sent to the appropriate	people for a problem or class of problem.

+ Create groups	based on administrative roles,	application	names, department names, or other criteria.	

+ Customize	filters	for	alerting different users based	on incident type and severity.	
  

![System Context Flow](static/imgs/ANS system context flow.png?raw=true)  

In this document you will understand how to setup IBM Alert Notification System (ANS) as part of the service management tool chain and demonstrate the interaction of ANS with the other tool chain components of the toolchain for operating the _BlueCompute_ hybrid application.

Any event recived by NOI for BlueCompute, regardless of its origin like Bluemix or Softlayer platform, has been enriched with the business service name _BlueCompute_. A single alert policies can here be used to alert any kind of BlueCompute related incidents to the FirstResponder on call.


IBM Alert Notification System is operated though a web based GUI called ANS UI, login is 

    https://{servicename}.mybluemix.net/index?subscriptionId={subscription-id}&dashboard=ans.dashboard.alertviewer 

Replace {servicename} and {subscription-id} with the address/subscription.id of your ANS instance.


##Step 1: Setup IBM Alert Notification System

For base setup of an ANS instance in your Bluemix environment, please follow the information of guide [Get started with the IBM Alert Notification Service](https://developer.ibm.com/cloudarchitecture/docs/service-management/ibm-alert-notification-service/) for "Adding the Alert Notification Service to your Bluemix Organization".

##Step 2: Define FirstResponder Users and Group for BlueCompute

For creating one or more FirstResponder users, their schedules and notification details to respond to ANS alerts around the business service _BlueCompute_, please follow the information of guide [Get started with the IBM Alert Notification Service](https://developer.ibm.com/cloudarchitecture/docs/service-management/ibm-alert-notification-service/) for "Adding Users, Groups and Schedules to ANS".

+ Create one or more users as FirstResponder for business service _BlueCompute_
    + Set User Name 
    + Define Working hours
    + Define Notification cases and means (email, SMS,..)

+ Create a group with the FirstResponder users
    + Set Group Name
    + Add users and owner
    + Define Notification schedule

##Step 3: Define an Alert Policy for BlueCompute

For creating an alert policy, which defines which ANS alerts should be notified to which user and groups, please follow the information of guide [Get started with the IBM Alert Notification Service](https://developer.ibm.com/cloudarchitecture/docs/service-management/ibm-alert-notification-service/) for "Notification and Escalation Policies".

### Setup a new Alert Policy for business service _BlueCompute_
The policy can rely on the settings which have been prepared during the posting of the event from NOI to ANS. The business service name _BlueCompute_ is always included in the ANS alert attribute `Application or ServiceName`. 

1. Create a new Alert Policy with name `BlueCompute`
2. Add a new rule, which will trigger on alerts for _BlueCompute_ with the following filter criterias:
    + Attribute = Application or ServiceName 
    + Operator  = Contains
    + Value     = BlueCompute
    
    ![Add rule](ANS_alert_policy_rule_for_BlueCompute.png?raw=true)  
3. Add another rule, which will trigger only on critical alerts by selecting the Pre-defined rule `Severity of alerts is critical or above`
4. Assure you select `Match all rules` to get both rules validated together
5. Add the recipient users and/or groups which should be notified based on the schedules
6. Optionally: add escalations and exceptions as appropriate

![Add policy](ANS_notification_policy_for_BlueCompute.png?raw=true) 

##Step 4: View and manage Alerts for BlueCompute

1. Open the ANS AlertViewer directly on 

    https://{servicename}.mybluemix.net/index?subscriptionId={subscription-id}&dashboard=ans.dashboard.alertviewer

    Replace {servicename} and {subscription-id} with the address/subscription.id of your ANS instance.
    
2. You can see all the existing alerts and your assigned alerts by selecting the `My Alerts` switch instead.


3. Selecting an alert will update the "Alert History` section with information about when the alert has been received and which notifications have been triggered.

![View alert history](ANS_alert_history.png?raw=true) 

4. Click on the "Acknowledge this alert" icon to change the state of the alert from `Notified` to `Acknowledged`.

5. Click on the "View alert details" icon to see the details about the event, including the setting for `Application or Services`

![View alert details](ANS_alert_details.png?raw=true) 





