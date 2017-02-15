import sys, requests, json, time, re

def main(dict):
  if 'slackwebhook' in dict:
    url = dict['slackwebhook']
  else:
    return {'result':'fail', 'status':'missing slack webhook URL'}
  
  if 'slack_channel'  in dict:
    slack_channel = dict['slack_channel']
  else:
    return {'result':'fail', 'status':'missing slack channel to post to'}
  if 'slack_username' in dict:
    slack_username = dict['slack_username']
  else:
    slack_username = 'openWhiskMonitor'
  
  msgvars = {
    'actionName': dict['name'],
    'namespace': dict['namespace'],
    'logs': '\n'.join(dict['logs']),
    'status': dict['response']['status'],
    'error': dict['response']['result']['error'],
    'raw_log': dict['logs']
  }
  
  payload={
      "channel": slack_channel, 
      "username": slack_username, 
      "icon_emoji": ":ghost:",
      "attachments": [
        {
            "fallback": "Activation of action %(actionName)s in namespace %(namespace)s failed." % msgvars,
            "color": "#ff0000",
            "pretext": "Invocation of whisk action failed",
            "fields": [
                {
                    "title": "ActionName",
                    "value": msgvars['actionName'],
                    "short": True
                },
                {
                    "title": "NameSpace",
                    "value": msgvars['namespace'],
                    "short": True
                },
                {
                    "title": "Status",
                    "value": msgvars['status'],
                    "short": True
                },
                {
                    "title": "Error",
                    "value": msgvars['error'],
                    "short": True
                },
                {
                    "title": "Log ouput",
                    "value": format_log(msgvars['raw_log']),
                    "short": False
                }
            ],
            "footer": "OpenWhisk Monitor",
            "footer_icon": "https://www.ibm.com/blogs/bluemix/wp-content/uploads/2016/02/openwhisk_hero_medium.png",
            "ts": int(time.time())
        }
    ]
  }

  r = requests.post(url, data=json.dumps(payload), headers={'Content-Type': 'application/json'})
  return {'slackstatus': r.status_code, 'incoming': dict}

def format_log(raw_log):
  message = ''
  for line in raw_log:
    # Remove timestamp
    l = re.sub(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d+Z ', '',  line)
    
    message = message + l + '\n'
    
  return message
    
