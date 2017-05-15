#!/bin/bash
#
# result saved in /opt/tests/speedtest_result.xml
#

cd /opt/tests/
rake spec | tee speedtest_result.log
awk -f filter_junit.awk speedtest_result.log > speedtest_result.xml
