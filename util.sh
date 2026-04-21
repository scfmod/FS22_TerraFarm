#!/bin/sh
M_PWD="$PWD" bun run --env-file "$PWD/.env" --env-file .env --silent --cwd ../FS22_ModUtils "$@"
