#!/bin/sh
set -e

# wait-for sbis-mysql:3306 -- echo 'sbis-mysql connnected'

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
