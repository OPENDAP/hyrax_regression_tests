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
