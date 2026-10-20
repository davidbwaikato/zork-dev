#!/usr/bin/env bash
# Compatibility entry point used by parent-project scripts.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file: source %q\n' "$0" >&2; exit 1
fi
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/prog-langs/ACTIVATE-PYTHON.bash"
