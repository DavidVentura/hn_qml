#!/bin.bash
export CLICKABLE_FRAMEWORK=ubuntu-sdk-20.04
set -euo pipefail
clickable build --arch all
clickable publish --arch all
