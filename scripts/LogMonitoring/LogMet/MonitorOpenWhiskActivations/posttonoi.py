import sys, requests, json

def main(dict):
  print 'Received data'
  print dict
  if 'omnibus_url' in dict:
    omnibus_url = dict['omnibus_url']
  else:
    return {'result':'fail', 'status':'missing omnibus url'}
  
  r = requests.post(omnibus_url, json=dict, headers={'Content-Type': 'application/json'})
  print r.text
  return {'result':r.text}
