# OpenWhisk Failed Activation Notifyer

Simple OpenWhisk action that polls OpenWhisk API, looks for failed activations and triggers a notification for for failed activations
Activations in every organisation and space that the user has access to in the current region will be scanned

The system has two steps
    
    1. getFailedActivations
       - This action is triggered periodically and scans all activations since last run, looking for failed activations
       - If a failed activation is found it triggers the notification trigger
    2. Notification
       - One or more notification actions are invoked when the notification trigger is fired


## Supported notification channels

- Slack
- IBM Netcool/OMNIbus
- IBM Bluemix LogMet

# Setup

## Create the notification trigger
```
wsk trigger create notificationTrigger
```
This trigger will be fired by the main activation poller action when a failed activation is found.


## Create the actions for the desired notification channels

### To create notification in Slack
```
wsk action create posttoslack posttoslack.py -p slackwebhook <webhookURL> -p slack_username <username> -p slack_channel <ChannelName?
wsk rule create postfailuretoslack notificationTrigger posttoslack
```
For more information on how to set up an incomming webhook in slack here: [https://api.slack.com/incoming-webhooks](https://api.slack.com/incoming-webhooks)

### To create an entry in NetCool/OMNIbus
```
wsk action create posttonoi posttonoi.py -p omnibus_url <omnibus_url>
wsk rule create postfailuretonoi notificationTrigger posttonoi
```

### To create an entry in LogMet
```
wsk action create posttologmet posttologmet.py -p logmet_host <logmet_host> -p logmet_port <logmet_port> -p logmet_token <logmet_token> -p space_id <space_id>
wsk rule create postfailuretologmet notificationTrigger posttologmet
```

To get the logmet token and space id, you can use the ```get_token.py``` script from the [pylogmet](https://github.com/locke105/pylogmet) github repository.

The posttologmet action receives failed activation notification from all activations in all spaces and organisations the current user has access to. However, it will create a logmet entry in a single logmet space, specified by space_id.
Inside logmet you can filter by 'space_name' and 'org_name' to see where what namespace the failed activation was running in.


## Create the main activation poller action
```
wsk action create getFailedActivations getFailedActivations.py
```

## Create the an alarm trigger and associated rule to initiate the polling
```
wsk trigger create everyMinute --feed /whisk.system/alarms/alarm -p cron "0 */1 * * * *" -p trigger_payload '{"poll_interval":60}'
wsk rule create getFailedActivations everyMinute getFailedActivations
```

Note: If you update the cron interval setting you must also update the poll_interval value in the trigger_payload, as this is the value given to the getFailedActivations action. getFailedActivations uses this value to know how far back to check activations.


