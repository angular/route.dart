#!/bin/bash

set -evx
. ./test/scripts/env.sh

node "node_modules/karma/bin/karma" start karma.conf \
  --reporters=junit,dots --port=8765 --runner-port=8766 \
  --browsers=Dartium,ChromeNoSandbox --single-run --no-colors

