#!/bin/bash
# typical has 10 concurrent users making 10,000 requests (10 users x 2 requests x 500 loops)
JMETER_HOME=/home/ubuntu/apache-jmeter-4.0
$JMETER_HOME/bin/jmeter -n -l logs/jmeter.log -t collection-api-load-test-typical.jmx
