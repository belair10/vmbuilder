#!/bin/bash
# Launch Burp headless just long enough to export its CA cert from the proxy's
# /cert endpoint. The Java process is fully detached (new session + closed
# stdio) so Ansible does not wait on it, and timeout force-kills it.
burp=$(find /opt/BurpSuiteCommunity -name 'burp*.jar' 2>/dev/null | tail -1)

setsid bash -c "timeout -k 5 45 /opt/BurpSuiteCommunity/jre/bin/java -Djava.awt.headless=true -jar '$burp' < <(echo y)" >/dev/null 2>&1 &

sleep 30
curl -s --max-time 15 http://localhost:8080/cert -o /tmp/cacert.der
exit 0
