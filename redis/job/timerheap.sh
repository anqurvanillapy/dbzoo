#!/usr/bin/env bash

#
# Heap-based timer.
#

# Command to run `redis-cli`.
# For example:
#   export REDIS_CLI_CMD=docker exec redis_redis_1 redis-cli
REDIS_CLI_CMD=${REDIS_CLI_CMD}
LOG_LEVEL=${LOG_LEVEL}

# Worker process to send basic timeout events.
function worker() {
  while sleep 0.1; do
    # TODO
    ${REDIS_CLI_CMD} ping
  done
}

# Run a job expression.
function run_expr() {
  local expr=$1
  IFS='|' read -r attr time cmd <<<"${expr}"
  debug "Running expression: attr=${attr}, time=${time}, cmd='${cmd}'"

  if [[ ${attr} != loop && ${attr} != once ]]; then
    panic "Attribute should be 'loop' or 'once', found '${attr}'"
  fi

  if [[ ${time} -le 0 ]]; then
    panic "Timeout should be > 0, found '${time}'"
  fi

  local ts
  ts=$(python -c "import time;print(int(time.time()*1000))")

  local tp
  tp=$(echo "$time" + "$ts" | bc)

  debug "Creating job: time=${time}, timestamp=${ts}, timepoint=${tp}"

  ${REDIS_CLI_CMD} zadd timerheap nx "${tp}" "${attr}|${time}|${cmd}"
}

# Debug log.
function debug() {
  if [[ ${LOG_LEVEL} != debug ]]; then return; fi
  echo "$(date "+%Y-%m-%d:%H:%M:%S")|DEBUG|$1"
}

# Exit with a error message.
function panic() {
  echo "$1"
  exit 1
}

function main() {
  while read -r line; do
    run_expr "${line}"
  done
}

# worker &
main
wait
