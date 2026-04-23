#!/usr/bin/env bash
set -euo pipefail

python -m pip install -r events/requirements.txt
python events/publish_event.py
