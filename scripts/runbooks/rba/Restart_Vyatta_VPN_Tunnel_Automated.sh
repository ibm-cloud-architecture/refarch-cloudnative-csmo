#/bin/bash
run=/opt/vyatta/bin/vyatta-op-cmd-wrapper
IFS=$'\n'
REGEXP="^.*([0-9])+.*down.*$"
for f in $( $run show vpn ipsec sa); do
        if [[ $f =~ $REGEXP ]]; then
             if [[ $TUNNEL_ID == ${BASH_REMATCH[1]} ]]; then
                $run reset vpn ipsec-peer $PEER_IP tunnel $TUNNEL_ID
             fi
        fi
done

sleep 180s
for f in $( $run show vpn ipsec sa); do
        if [[ $f =~ $REGEXP ]]; then
             if [[ $TUNNEL_ID == ${BASH_REMATCH[1]} ]]; then
                $run reset vpn ipsec-peer $PEER_IP tunnel $TUNNEL_ID
             fi
        fi
done

echo "Check status after final restart"
$run show vpn ipsec sa
