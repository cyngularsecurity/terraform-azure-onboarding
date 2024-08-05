#!/usr/bin/env bash
set -eu

# python3 -m venv .env
# source .env/bin/activate
# pip install -r requirements.txt

# Package your function app
zip -r9 cyngular_func .

# rm -rf .env