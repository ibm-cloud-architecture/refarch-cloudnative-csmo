#/bin/bash
run=/opt/vyatta/bin/vyatta-op-cmd-wrapper
$run reset vpn ipsec-peer $PEER_IP tunnel $TUNNEL_ID
$run show vpn ipsec sa
