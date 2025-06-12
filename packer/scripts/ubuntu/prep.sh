#!/bin/bash
# Reset machine-id
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Remove SSH host keys
rm -f /etc/ssh/ssh_host_*

# Clean cloud-init
cloud-init clean --logs --seed

# Optional: Clear logs
journalctl --rotate
journalctl --vacuum-time=1s

/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync