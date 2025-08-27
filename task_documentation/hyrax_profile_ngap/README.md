# Current scratch

# From unit test run via debugger!
cat /Users/hrobertson/OPeNDAP/hyrax/bes/HANNAH_bes.log | beslog2json.py -t t > tmp.json;
cat tmp.json | jq '.|select(."pid"==97868) | select(."timer-name"!=null)' > timers.json

## Sorted 
cat timers.json | jq --slurp 'sort_by(."start-us")[] | ."timer-name"' > timers-sorted.json

## All not just timers 
cat tmp.json | jq '.|select(."pid"==97868)' > messages.json
cat messages.json | jq --slurp 'sort_by(."time")[] | ."timer-name"' > messages-sorted.json

--------------

# From end-to-end via olfs 
cat /Users/hrobertson/OPeNDAP/hyrax/build/var/bes.log | beslog2json.py -t t > tmp2.json;
cat tmp2.json | jq '.|select(."pid"==8442) | select(."timer-name"!=null)' > timers2.json

## Sorted 
cat timers2.json | jq --slurp 'sort_by(."start-us")[] | ."timer-name"' > timer2-sorted.json

## All not just timers 
cat tmp2.json | jq '.|select(."pid"==8442)' > messages2.json
cat messages2.json | jq --slurp 'sort_by(."time")[] | ."timer-name"' > messages2-sorted.json

----

## Pre-processing

1a. Pull out the profiling statements from local log
```
cat /Users/hrobertson/OPeNDAP/hyrax/build/var/bes.log | /Users/hrobertson/OPeNDAP/hyrax/bes/server/beslog2json.py | jq --slurp > bes_log.json
```
cat full_daymet_test.log | /Users/hrobertson/OPeNDAP/hyrax/bes/server/beslog2json.py -t t | jq --slurp > bes_log.json


1b. Download the profiling statments from cloudwatch logs
```
aws configure  # will prompt for aws credentials
aws configure set aws_session_token <SESSION_TOKEN>

aws logs filter-log-events \
--log-group-name hyrax-<foo> \
--start-time 1756242340000 \
--end-time 1756244560000 \
--output json > output_log.json
```