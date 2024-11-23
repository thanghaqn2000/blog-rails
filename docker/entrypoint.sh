#!/bin/sh
set -e
rails db:migrate
exec "$@"
