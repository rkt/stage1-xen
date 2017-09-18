#!/bin/bash

set -e

# runit RPM creates `/etc/service` directory
if [ ! -d "/etc/service" ]; then
    echo "/etc/service directory not found."
    exit 1
fi

runit_services="xenconsoled xen-init-dom0 xen-init-dom0-disk-backend xenstored"

for service in $runit_services; do
    rm -f /etc/service/$service
done

echo "Successfully deleted symlinks in /etc/service directory."
exit 0
