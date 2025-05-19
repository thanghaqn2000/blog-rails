#!/bin/sh
set -e
rails db:prepare
exec "$@"
