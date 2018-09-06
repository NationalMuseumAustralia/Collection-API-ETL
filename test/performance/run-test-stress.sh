#!/bin/bash
# stress has 20 concurrent users making 40,000 requests (20 users x 2 requests x 1,000 loops)
JMETER_HOME=/home/ubuntu/apache-jmeter-4.0
$JMETER_HOME/bin/jmeter -n -t collection-api-load-test-stress.jmx
