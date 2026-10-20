#!/usr/bin/env bash
# Replay the complete pip-freeze snapshot from the user's working Windows GPU
# installation. Keep every recorded version, including its CUDA build suffix.
set -euo pipefail
export ZORKS_COMFYUI_PROFILE=windows-exact
ZORKS_SNAPSHOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_SNAPSHOT_DIR/../versions.env"
source "$ZORKS_SNAPSHOT_DIR/../prog-langs/_common.bash"
zorks_dev_detect_host
ZORKS_COMFYUI_PROFILE=windows-exact zorks_dev_resolve_comfyui_profile
ZORKS_SNAPSHOT_PY="$(zorks_dev_python_executable "$(cd -- "$ZORKS_SNAPSHOT_DIR/.." && pwd -P)")"
ZORKS_SNAPSHOT_FILE="$ZORKS_SNAPSHOT_DIR/comfyui_exact_requirements_win64.txt"
[[ -x "$ZORKS_SNAPSHOT_PY" ]] || zorks_dev_die 'Install the project Python environment first'
[[ -s "$ZORKS_SNAPSHOT_FILE" ]] || zorks_dev_die 'The Windows ComfyUI requirements snapshot is missing'
printf 'Installing the recorded Windows CUDA 13.0 ComfyUI environment from %s\n' "$ZORKS_SNAPSHOT_FILE"
# All versions are explicit == pins. A resolver conflict is reported as an
# error; the installer never substitutes a generic torch family or silently
# changes a recorded version. The CUDA index provides the +cu130 wheels.
"$ZORKS_SNAPSHOT_PY" -m pip install \
  --extra-index-url https://download.pytorch.org/whl/cu130 \
  -r "$ZORKS_SNAPSHOT_FILE"

# Verify the full recorded inventory, not just the torch versions. Read CRLF
# files without rewriting the user's authoritative snapshot.
"$ZORKS_SNAPSHOT_PY" - "$ZORKS_SNAPSHOT_FILE" <<'PYVERIFY'
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path
import re
import sys
errors = []
count = 0
for line in Path(sys.argv[1]).read_text().splitlines():
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    match = re.fullmatch(r'([A-Za-z0-9_.-]+)==([^\s;]+)', line)
    if not match:
        errors.append('Unsupported snapshot entry: ' + line)
        continue
    name, expected = match.groups()
    count += 1
    try:
        actual = version(name)
    except PackageNotFoundError:
        errors.append(name + ': not installed')
        continue
    if actual != expected:
        errors.append(f'{name}: expected {expected}, found {actual}')
if errors:
    raise SystemExit('Windows snapshot verification failed:\n' + '\n'.join(errors))
print(f'Verified all {count} recorded Windows package versions.')
PYVERIFY

"$ZORKS_SNAPSHOT_PY" -m pip check

# Confirm that the installed build can execute a CUDA operation. Timing the
# complete Flux workflow remains a separate native Windows test.
"$ZORKS_SNAPSHOT_PY" - <<'PYGPU'
import torch
print('PyTorch:', torch.__version__, 'CUDA build:', torch.version.cuda)
if not torch.cuda.is_available():
    raise SystemExit('The Windows snapshot is installed, but CUDA is unavailable. Check the NVIDIA driver before running the GPU workflow; use the portable profile for a CPU installation.')
value = torch.ones(1, device='cuda') * 2
torch.cuda.synchronize()
assert value.item() == 2
print('CUDA operation passed on:', torch.cuda.get_device_name(0))
PYGPU
printf 'Recorded Windows ComfyUI packages installed and verified.\n'
