#!/bin/bash

terraform apply -target=packet_device.master && \
terraform apply -target=dnsimple_record.master -target=dnsimple_record.server_discovery -target=dnsimple_record.client_discovery -target=dnsimple_record.master_internal_rr -target=dnsimple_record.master_rr && \
terraform apply -target=packet_device.worker && \
terraform apply
