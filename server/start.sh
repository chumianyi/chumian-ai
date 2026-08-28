#!/bin/bash
cd "$(dirname "$0")"
export CHUMIAN_DB_PATH="$(pwd)/data/chumian.db"
export CHUMIAN_MEDIA_DIR="$(pwd)/media"
exec python3 main.py
