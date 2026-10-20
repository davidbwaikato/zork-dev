#!/usr/bin/env bash
# Build the pinned CPU server against this Linux host's own system libraries.
set -euo pipefail
ZORKS_LLAMA_BUILD_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_LLAMA_BUILD_SCRIPT_DIR/../prog-langs/_common.bash"
source "$ZORKS_LLAMA_BUILD_SCRIPT_DIR/_llama_cpp_env.bash"
zorks_dev_detect_host
[[ "$ZORKS_DEV_OS" == linux ]] || zorks_dev_die 'The local source-build fallback currently supports Linux only'

ZORKS_LLAMA_CC="${CC:-cc}"
ZORKS_LLAMA_CXX="${CXX:-c++}"
command -v "$ZORKS_LLAMA_CC" >/dev/null 2>&1 || zorks_dev_die 'Building llama.cpp requires a C compiler (cc/gcc). Install build tools separately or set CC.'
command -v "$ZORKS_LLAMA_CXX" >/dev/null 2>&1 || zorks_dev_die 'Building llama.cpp requires a C++17 compiler (c++/g++). Install build tools separately or set CXX.'
command -v make >/dev/null 2>&1 || zorks_dev_die 'Building llama.cpp requires make. Install build tools separately.'
ZORKS_LLAMA_JOBS="${ZORKS_LLAMA_BUILD_JOBS:-2}"
[[ "$ZORKS_LLAMA_JOBS" =~ ^[1-9][0-9]*$ ]] || zorks_dev_die 'ZORKS_LLAMA_BUILD_JOBS must be a positive integer'
ZORKS_LLAMA_BUILD_ROOT="$ZORKS_LLAMA_BUILD_SCRIPT_DIR/llama-cpp-build"
ZORKS_LLAMA_WORK="$ZORKS_LLAMA_BUILD_ROOT/$LLAMA_CPP_BUILD-$ZORKS_DEV_ARCH"
ZORKS_LLAMA_SOURCE="$ZORKS_LLAMA_WORK/source"
ZORKS_LLAMA_OBJECTS="$ZORKS_LLAMA_WORK/build"
ZORKS_LLAMA_ARCHIVE="$LLAMA_CPP_DOWNLOAD_DIR/llama.cpp-$LLAMA_CPP_BUILD.tar.gz"
mkdir -p "$ZORKS_LLAMA_WORK" "$LLAMA_CPP_DOWNLOAD_DIR"

# GCC 8 (Debian 10's default) may need the separate C++17 filesystem library.
# Detect this by linking a probe, rather than assuming all Linux compilers are
# recent or appending an unavailable library on other compiler families.
ZORKS_LLAMA_PROBE="$(mktemp -d "$ZORKS_LLAMA_WORK/.compiler-probe.XXXXXX")"
ZORKS_LLAMA_STAGE=''
cleanup_zorks_llama_build() {
  rm -rf -- "$ZORKS_LLAMA_PROBE"
  if [[ -n "$ZORKS_LLAMA_STAGE" ]]; then rm -rf -- "$ZORKS_LLAMA_STAGE"; fi
}
trap cleanup_zorks_llama_build EXIT
cat > "$ZORKS_LLAMA_PROBE/probe.cpp" <<'CPPPROBE'
#include <filesystem>
int main() { return std::filesystem::exists(".") ? 0 : 1; }
CPPPROBE
ZORKS_LLAMA_FILESYSTEM_ARGS=()
if ! "$ZORKS_LLAMA_CXX" -std=c++17 "$ZORKS_LLAMA_PROBE/probe.cpp" -o "$ZORKS_LLAMA_PROBE/probe" > "$ZORKS_LLAMA_PROBE/compiler.log" 2>&1; then
  if "$ZORKS_LLAMA_CXX" -std=c++17 "$ZORKS_LLAMA_PROBE/probe.cpp" -lstdc++fs -o "$ZORKS_LLAMA_PROBE/probe" >> "$ZORKS_LLAMA_PROBE/compiler.log" 2>&1; then
    ZORKS_LLAMA_FILESYSTEM_ARGS=(-DCMAKE_CXX_STANDARD_LIBRARIES=-lstdc++fs)
    printf 'Using the additional C++17 filesystem library required by this compiler.\n'
  else
    cat "$ZORKS_LLAMA_PROBE/compiler.log" >&2
    zorks_dev_die 'The C++ compiler could not link a C++17 filesystem program. Set CXX to a suitable compiler.'
  fi
fi

# Debian 10's packaged CMake predates llama.cpp's 3.14 minimum. Bootstrap a
# pinned wheel in a separate, ignored build-tools venv when necessary; do not
# alter the system or either application's Python package profile.
zorks_llama_cmake_usable() {
  local version
  version="$("$1" --version 2>/dev/null | sed -n '1s/.*version \([0-9][0-9.]*\).*/\1/p')" || return 1
  [[ -n "$version" ]] || return 1
  awk -v v="$version" 'BEGIN { split(v,a,"."); exit !(a[1]>3 || (a[1]==3 && a[2]>=14)) }'
}
ZORKS_LLAMA_CMAKE="${ZORKS_LLAMA_CMAKE:-}"
if [[ -n "$ZORKS_LLAMA_CMAKE" ]]; then
  zorks_llama_cmake_usable "$ZORKS_LLAMA_CMAKE" || zorks_dev_die 'ZORKS_LLAMA_CMAKE must name a working CMake 3.14 or newer'
elif command -v cmake >/dev/null 2>&1 && zorks_llama_cmake_usable "$(command -v cmake)"; then
  ZORKS_LLAMA_CMAKE="$(command -v cmake)"
else
  ZORKS_LLAMA_TOOLS="$ZORKS_LLAMA_BUILD_ROOT/build-tools"
  if [[ ! -x "$ZORKS_LLAMA_TOOLS/bin/python" ]]; then
    ZORKS_LLAMA_BOOTSTRAP_PY="$ZORKS_LLAMA_BUILD_SCRIPT_DIR/../prog-langs/python-for-zork/bin/python"
    [[ -x "$ZORKS_LLAMA_BOOTSTRAP_PY" ]] || zorks_dev_die 'Run dev/prog-langs/INSTALL-PYTHON.sh first; its Python is needed to install a local CMake'
    "$ZORKS_LLAMA_BOOTSTRAP_PY" -m venv "$ZORKS_LLAMA_TOOLS"
  fi
  ZORKS_LLAMA_CMAKE="$ZORKS_LLAMA_TOOLS/bin/cmake"
  if ! zorks_llama_cmake_usable "$ZORKS_LLAMA_CMAKE"; then
    "$ZORKS_LLAMA_TOOLS/bin/python" -m pip install --only-binary=:all: 'cmake==3.31.6'
  fi
  zorks_llama_cmake_usable "$ZORKS_LLAMA_CMAKE" || zorks_dev_die 'The project-local CMake could not run'
fi

if [[ -f "$ZORKS_LLAMA_ARCHIVE" ]] && [[ "$(llama_cpp_sha256_file "$ZORKS_LLAMA_ARCHIVE")" != "$LLAMA_CPP_SOURCE_SHA256" ]]; then
  zorks_dev_die "Cached llama.cpp source checksum mismatch. Preserve or remove $ZORKS_LLAMA_ARCHIVE and retry."
fi
if [[ ! -f "$ZORKS_LLAMA_ARCHIVE" ]]; then
  printf 'Downloading pinned llama.cpp %s source...\n' "$LLAMA_CPP_BUILD"
  zorks_dev_download "https://github.com/ggml-org/llama.cpp/archive/refs/tags/$LLAMA_CPP_BUILD.tar.gz" "$ZORKS_LLAMA_ARCHIVE"
fi
[[ "$(llama_cpp_sha256_file "$ZORKS_LLAMA_ARCHIVE")" == "$LLAMA_CPP_SOURCE_SHA256" ]] || zorks_dev_die 'Downloaded llama.cpp source checksum mismatch'
if [[ ! -f "$ZORKS_LLAMA_SOURCE/CMakeLists.txt" ]]; then
  [[ ! -e "$ZORKS_LLAMA_SOURCE" ]] || zorks_dev_die "Incomplete source tree at $ZORKS_LLAMA_SOURCE; move it aside and retry"
  ZORKS_LLAMA_STAGE="$(mktemp -d "$ZORKS_LLAMA_WORK/.source-stage.XXXXXX")"
  tar --no-same-owner --strip-components=1 -xzf "$ZORKS_LLAMA_ARCHIVE" -C "$ZORKS_LLAMA_STAGE"
  [[ -f "$ZORKS_LLAMA_STAGE/CMakeLists.txt" ]] || zorks_dev_die 'The source archive lacked CMakeLists.txt'
  zorks_dev_move_with_retry "$ZORKS_LLAMA_STAGE" "$ZORKS_LLAMA_SOURCE"
  ZORKS_LLAMA_STAGE=''
fi
# Apply a deterministic, type-preserving workaround for GCC 8's CTAD failure
# in new field_num(...). This also patches an existing cached source tree and
# leaves its timestamps untouched on later runs so the build stays incremental.
ZORKS_LLAMA_PATCH_PY="$ZORKS_LLAMA_BUILD_SCRIPT_DIR/../prog-langs/python-for-zork/bin/python"
if [[ ! -x "$ZORKS_LLAMA_PATCH_PY" ]]; then
  ZORKS_LLAMA_PATCH_PY="$(command -v python3)" || zorks_dev_die 'Python 3 is needed to apply the GCC 8 source compatibility patch'
fi
"$ZORKS_LLAMA_PATCH_PY" "$ZORKS_LLAMA_BUILD_SCRIPT_DIR/patch-llama-cpp-gcc8.py" "$ZORKS_LLAMA_SOURCE"

printf 'Building llama.cpp %s CPU server on this Linux host (%s jobs)...\n' "$LLAMA_CPP_BUILD" "$ZORKS_LLAMA_JOBS"
"$ZORKS_LLAMA_CMAKE" -S "$ZORKS_LLAMA_SOURCE" -B "$ZORKS_LLAMA_OBJECTS" -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Release \
  "-DCMAKE_C_COMPILER=$ZORKS_LLAMA_CC" "-DCMAKE_CXX_COMPILER=$ZORKS_LLAMA_CXX" \
  -DBUILD_SHARED_LIBS=OFF -DGGML_BACKEND_DL=OFF -DGGML_NATIVE=ON \
  -DGGML_CUDA=OFF -DGGML_VULKAN=OFF -DGGML_HIP=OFF -DGGML_SYCL=OFF \
  -DLLAMA_OPENSSL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_APP=OFF -DLLAMA_BUILD_UI=OFF -DLLAMA_USE_PREBUILT_UI=OFF -DLLAMA_BUILD_TOOLS=ON -DLLAMA_BUILD_SERVER=ON \
  -DLLAMA_BUILD_NUMBER="${LLAMA_CPP_BUILD#b}" "${ZORKS_LLAMA_FILESYSTEM_ARGS[@]}"
"$ZORKS_LLAMA_CMAKE" --build "$ZORKS_LLAMA_OBJECTS" --target llama-server --parallel "$ZORKS_LLAMA_JOBS"
[[ -x "$ZORKS_LLAMA_OBJECTS/bin/llama-server" ]] || zorks_dev_die 'The source build did not produce llama-server'
"$ZORKS_LLAMA_OBJECTS/bin/llama-server" --version

# Publish only after validation, preserving an existing incompatible installation
# for inspection. Keep this copy operation safe for user paths containing spaces.
ZORKS_LLAMA_STAGE="$(mktemp -d "$ZORKS_LLAMA_BUILD_SCRIPT_DIR/.llama-cpp-install.XXXXXX")"
cp "$ZORKS_LLAMA_OBJECTS/bin/llama-server" "$ZORKS_LLAMA_STAGE/llama-server"
cp "$ZORKS_LLAMA_SOURCE/LICENSE" "$ZORKS_LLAMA_STAGE/LICENSE"
printf 'CPU source build %s; OpenSSL disabled; built for %s\n' "$LLAMA_CPP_BUILD" "$(uname -m)" > "$ZORKS_LLAMA_STAGE/BUILD-INFO.txt"
"$ZORKS_LLAMA_STAGE/llama-server" --version
if [[ -e "$LLAMA_CPP_INSTALL_DIR" ]]; then
  ZORKS_LLAMA_BACKUP="$ZORKS_LLAMA_BUILD_ROOT/previous-install-$(date +%Y%m%d%H%M%S)-$$"
  zorks_dev_move_with_retry "$LLAMA_CPP_INSTALL_DIR" "$ZORKS_LLAMA_BACKUP"
  printf 'Previous llama.cpp installation preserved in %s\n' "$ZORKS_LLAMA_BACKUP"
fi
zorks_dev_move_with_retry "$ZORKS_LLAMA_STAGE" "$LLAMA_CPP_INSTALL_DIR"
ZORKS_LLAMA_STAGE=''
printf 'Installed and verified locally built llama.cpp: %s\n' "$LLAMA_CPP_SERVER_PATH"
