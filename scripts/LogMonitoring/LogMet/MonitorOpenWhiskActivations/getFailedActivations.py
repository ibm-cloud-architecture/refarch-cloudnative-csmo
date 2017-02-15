import time, os, sys, requests
from requests.auth import HTTPBasicAuth

# Some global settings
api_host = os.environ['__OW_API_HOST']
api_key = os.environ['__OW_API_KEY']
user, passwd = api_key.split(':')
myNamespace = os.environ['__OW_NAMESPACE']

# The name of the OpenWhisk trigger to fire when failed activations are found
notificationTrigger = 'notificationTrigger'

headers = {
  'accept': "application/json",
  'content-type': "application/json"
}

def main(dict):

  # Set the time for when to pull logs from
  now = int(time.time())
  if 'poll_interval' in dict:
    poll_interval = dict['poll_interval']
  else:
    poll_interval = 60 # seconds
  
  activations_since = now - poll_interval + 2 # Overlap polls by 2 seconds in leu of saving last activation number 
    
  # Get a list of all namespaces
  url = api_host + '/api/v1/namespaces'
  r = requests.get(url, headers=headers, auth=(user, passwd))
  if r.status_code != 200:
    print r.text
    return {'result': 'fail', 'reason': r.text}
  
  # Save the list of namespaces
  namespaces = r.json()
  
  # Get activations in each namespace
  for namespace in namespaces:
    url = api_host + '/api/v1/namespaces/%s/activations?docs=True&since=%i' % (namespace, activations_since * 1000)
    r = requests.get(url, headers=headers, auth=(user, passwd))
    if r.status_code != 200:
      print r.text
      return {'result': 'fail', 'reason': r.text}
    
    for activation in r.json():
      if not activation['response']['success']:
        notify_activation_failure(activation)
        
  return {'success': 'total'}
        
        
def notify_activation_failure(activation):
  namespace = myNamespace

  url = api_host + '/api/v1/namespaces/%s/triggers/%s' % (namespace, notificationTrigger)

  r = requests.post(url, json=activation, headers=headers, auth=(user, passwd))
  if r.status_code != 200:
    print r.text
    return {'result': 'fail', 'reason': r.text}

  return True
    
  

