#!/bin/bash

set -e

# runit RPM creates `/etc/service` directory
if [ ! -d "/etc/service" ]; then
    echo "/etc/service directory not found. Please install runit RPM."
    exit 1
fi

runit_services="xenconsoled xen-init-dom0 xen-init-dom0-disk-backend xenstored"

for service in $runit_services; do
    ln -sf /opt/xen-4.9.0-runit/$service /etc/service/$service
done

echo "Successfully created symlinks in /etc/service directory."
exit 0
