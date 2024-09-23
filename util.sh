#!/bin/sh
bun run --env-file "$PWD/.env" --env-file .env --silent --cwd ../FS22_ModUtils "$@"