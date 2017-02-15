import sys, requests, json

def main(dict):
  print 'Received data'
  print dict
  
  missing_values = []
  required_values = ['logmet_host', 'logmet_port', 'space_id', 'logmet_token']
  for key in required_values:
    if not key in dict:
      missing_values.append(key)
  
  if len(missing_values) > 0:
    return {'result':'fail', 'status':'missing required keys', 'keys': missing_keys}
  
  # Setup connection with Logmet
  lm = Logmet(
            logmet_host = dict['logmet_host'],
            logmet_port = dict['logmet_port'],
            token       = dict['logmet_token'],
            space_id    = dict['space_id']
  )
  
  # Parse the incoming data, and create a message dict to send to logmet.
  ## Any key in the message dictionary will appear as a field in Kibana.
  message = {
    'type': 'openwhisk',
    'origin': 'openwhisk',
    'message': dict
  }
  if 'name' in dict:
    message['app_name'] = dict['name']
  if 'namespace' in dict:
    message['space_name'] = dict['namespace'].split("_", 1)[1]
    message['org_name']   = dict['namespace'].split("_", 1)[0]
  if 'logs' in dict:
    message['logs'] = dict['logs']
  
  # Post the message to logmet
  lm.emit_log(message)
  return {'result':'probably successful'}


# This is just a copy/paste of the python logmet class from https://github.com/locke105/pylogmet
import logging
import select
import socket
import ssl
import struct
import time

LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)


class Logmet(object):
    """
    Simple client for sending metrics to Logmet.
    To use::
        import logmet
        lm = logmet.Logmet(
            logmet_host='metrics.opvis.bluemix.net',
            logmet_port=9095,
            space_id='deadbbeef1234567890',
            token='put_your_logmet_logging_token_here'
        )
        lm.emit_metric(name='logmet.test.1', value=1)
        lm.emit_metric(name='logmet.test.2', value=2)
        lm.emit_metric(name='logmet.test.3', value=3)
    """

    default_timeout = 20.0  # seconds

    def __init__(self, logmet_host, logmet_port, space_id, token):
        self.space_id = space_id
        self._token = token
        self.logmet_host = logmet_host
        self.logmet_port = logmet_port

        self._connect()

    def _connect(self):
        try:
            ssl_context = ssl.create_default_context()
            self.socket = ssl_context.wrap_socket(
                socket.socket(socket.AF_INET),
                server_hostname=self.logmet_host)
        except AttributeError:
            # build our own then; probably not secure, but logmet
            # doesn't seem to check/verify certs?
            self.socket = ssl.wrap_socket(
                socket.socket(socket.AF_INET))

        self.socket.settimeout(self.default_timeout)
        self.socket.connect((self.logmet_host, int(self.logmet_port)))

        self._auth_handshake()

        self._conn_sequence = None

    def _conn_is_dropped(self):
        # logmet appears to shutdown its side after 2 minutes
        # of inactivity on the TCP connection, so...
        # check to see if we got a close message
        list_tup = select.select([self.socket], [], [], 0)
        rlist = list_tup[0]
        return bool(rlist)

    def _assert_conn(self):
        if self._conn_is_dropped():
            LOG.info('Detected closed connection. Reconnecting.')
            self.socket.close()
            self.socket = None
            self._connect()

    def emit_metric(self, name, value, timestamp=None):
        self._assert_conn()

        if timestamp is None:
            timestamp = time.time()

        metric_fmt = '{0}.{1} {2} {3}\r\n'
        metric_msg = metric_fmt.format(
            self.space_id, name, value, timestamp)

        self._send_metric(metric_msg)
        
    
    def emit_log(self, message):
      self._assert_conn()
      
      message = dict(message)
      # The tenant ID must be included for the message to be accepted
      message['ALCH_TENANT_ID'] = self.space_id
      
      encoded = self._pack_dict(message)
      
      self._send_log(encoded)
      
      

      
    def unused_pack_dict(msg):
      """
      :param msg: the dict type msg to pack in byte format
      :return:
      """
      parts = []
      total_keys = len(msg)
      for key, value in msg.iteritems():
          if isinstance(key, unicode):
            enc_key = key.encode('utf-8', 'replace')
          else:
            enc_key = str(key)
          
          if isinstance(value, unicode):
            enc_value = value.encode('utf-8', 'replace')
          else:
            enc_value = str(value)
          
          if not enc_value:
              # Empty values can cause problems
              total_keys -= 1
              continue
          parts.extend([
              _pack_int(len(key)),
              key,
              _pack_int(len(value)),
              value,
          ])
        # result
        # 1D - total keys - lenKey - key - lenValue - value

      return _pack_int(total_keys) + ''.join(parts)

    def _pack_dict(self, msg):
        """
        :param msg: the dict type msg to pack in byte format
        :return:
        """
        parts = []
        total_keys = len(msg)
        for key, value in msg.iteritems():
            key = self._encode_unicode(key)
            value = self._encode_unicode(value)
            if not value:
                # Fix for logmet defect 126839
                total_keys -= 1
                continue
            parts.extend([
                self._pack_int(len(key)),
                key,
                self._pack_int(len(value)),
                value,
            ])
        print total_keys
        print parts
        print 'packed dict to ' + self._pack_int(total_keys) + ''.join(parts)
        return self._pack_int(total_keys) + ''.join(parts)


    def _encode_unicode(self, obj):
        if isinstance(obj, unicode):
            return obj.encode('utf-8', 'replace')
        else:
            return str(obj)


    def _pack_int(self, i):
        """
        Pack an int into a 4 byte string big endian.
        """
        return struct.pack('!I', i)

    def _wrap_for_send(self, messages, message_type):
        # message_types: 1M for metrics, 1D for data (logs)
        msg_wrapper = '1W' 
        #+ struct.pack('!I', len(messages))
        print 'len messages: '
        print len(messages)
        for idx, mesg in enumerate(messages, start=1):
            msg_wrapper += (message_type +
                            struct.pack('!I', self._conn_sequence) +
                            mesg)
            self._conn_sequence += 1
        return msg_wrapper

      
    def _send_log(self, message):
      if isinstance(message, unicode):
        # turn unicode into bytearray/str
        encoded_message = message.encode('utf-8', 'replace')
      else:
        # cool, already encoded
        encoded_message = str(message)     
      
      if self._conn_sequence is None:
        self._conn_sequence = 1
  
      message_package = '1W' + self._pack_int(1) + '1D' + self._pack_int(self._conn_sequence) + encoded_message
      self._conn_sequence += 1
      
      LOG.debug(
        "Sending wrapped messages: [{}]".format(
          message_package.encode(
            'string_escape',
            errors='backslashreplace'
          )
        )
      )
      acked = False
      while not acked:
        self.socket.sendall(message_package)

        try:
          resp = self.socket.recv(16)
          LOG.debug('Ack buffer: [{}]'.format(resp))
          if not resp.startswith('1A'):
            LOG.warning(
              'Unexpected ACK response from recv: [{}]'.format(resp)
            )
            time.sleep(0.1)
          else:
            acked = True
        except Exception:
          LOG.warning('No ACK received from server!')

      LOG.debug('Log message sent to logmet successfully')
        


    def _send_metric(self, message):
        if isinstance(message, unicode):
            # turn unicode into bytearray/str
            encoded = message.encode('utf-8', 'replace')
        else:
            # cool, already encoded
            encoded = str(message)

        packed_metric = struct.pack('!I', len(message)) + encoded

        if self._conn_sequence is None:
            self._conn_sequence = 1

        metrics_package = self._wrap_for_send([packed_metric], '1M')
        LOG.debug(
            "Sending wrapped messages: [{}]".format(
                metrics_package.encode(
                    'string_escape',
                    errors='backslashreplace'
                )
            )
        )

        acked = False
        while not acked:
            self.socket.sendall(metrics_package)

            try:
                resp = self.socket.recv(16)
                LOG.debug('Ack buffer: [{}]'.format(resp))
                if not resp.startswith('1A'):
                    LOG.warning(
                        'Unexpected ACK response from recv: [{}]'.format(resp)
                    )
                    time.sleep(0.1)
                else:
                    acked = True
            except Exception:
                LOG.warning('No ACK received from server!')

        LOG.debug('Metrics sent to logmet successfully')

    def _auth_handshake(self):
        # local connection IP addr
        ident = str(self.socket.getsockname()[0])

        ident_fmt = '1I{0}{1}'
        ident_msg = ident_fmt.format(chr(len(ident)), ident)

        self.socket.sendall(ident_msg)

        auth_fmt = '2T{0}{1}{2}{3}'
        auth_msg = auth_fmt.format(
                chr(len(self.space_id)),
                self.space_id,
                chr(len(self._token)),
                self._token)

        self.socket.sendall(auth_msg)

        resp = self.socket.recv(16)
        if not resp.startswith('1A'):
            raise Exception('Auth failure!')
        LOG.info('Auth to logmet successful')

    def close(self):
        # nicely close
        self.socket.shutdown(1)
        time.sleep(0.1)
        self.socket.close()
