#!/usr/bin/env bash
# Compatibility entry point; canonical installer also supports Unix.
set -euo pipefail
exec "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/INSTALL-ZILF.sh" "$@"
