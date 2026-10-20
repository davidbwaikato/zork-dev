# Cross-platform dev refresh for NerdFest 2026

Prepared 20 October 2026 from the supplied Zorks Illustrated and Musical Atrium
`dev` archives.

- Adopted Musical Atrium's central language pins, versioned local installations,
  download caches and separate install/activation scripts.
- Added Linux/macOS Node.js installation and consistent Python host selection
  for x64 and ARM64. Kept Zorks' `python-for-zork` environment directory.
- Added local Unix dfrotz builds and native ZILF package installation where
  upstream publishes a package. Existing dfrotz on PATH is accepted.
- Kept the existing pinned llama.cpp release, interpreter model, installation
  paths and application environment variables.
- Made installation scripts independent of the current directory and handled
  checkout paths with spaces. Activation preserves cwd and shell options,
  avoids duplicate tool paths, and supports switching between checkouts.
- Fixed the Stable Audio installer typo and removed unattended login prompts.
- Added two explicit installation profiles: regular package resolution for the
  running Python and selected CPU/CUDA/macOS backend, and the unchanged measured
  Windows 11 package snapshot. The regular profile is the default on every OS.
- Kept regular, Windows snapshot and Stable Audio dependencies in separate venvs.
  The Windows snapshot restores the original Zorks Python 3.12.13 pin and uses
  its exact recorded +cu130 wheels, without a generic torch installation before
  or an unpinned ComfyUI requirements pass afterward.
- Replaced the Linux-sensitive ComfyUI lockfile case mismatch with upstream
  requirements and a constraint protecting the selected torch family.
- Kept forwarding wrappers for old installer names and Python activation.
- Included source and configuration templates only; installers obtain runtime
  binaries, upstream code, dependencies and model weights as needed.

## Verification

Fresh Linux x64 installation was performed in a directory containing spaces and
an ampersand, then repeated to verify reuse:

- Node.js v24.18.0 and pnpm 11.25.0 installed and executed.
- Portable CPython 3.12.14 and the main venv installed; `pip check` passed.
- Frotz 2.55 built from source; dfrotz executed.
- ZILF 1.9 installed from its verified native package; it compiled a small ZIL
  story, which dfrotz ran and printed `Hello, world!`.
- Existing llama.cpp b10516 installer downloaded, verified, installed and ran
  `llama-server --version` successfully.
- ComfyUI 0.22.0 source installer downloaded and unpacked its release.
- All 33 shell entry points passed `bash -n`.
- All 32 offline test methods passed, including the six host combinations,
  checksum rejection, download failure propagation, install reuse, activation
  preservation and checkout switching, backend selection, Windows default regular
  behavior, explicit snapshot use, snapshot failure propagation, separate Python
  pins and venvs, profile activation switching, Stable Audio isolation, binary
  runtime validation, fallback dispatch, source checksum checks, GCC 8 filesystem
  handling, preservation of an existing installation after a build failure,
  repeatable source patching without timestamp changes, rejection of unexpected
  source edits, and numeric type/reference preservation by the GCC 8 workaround.
- Confirmed the Windows snapshot requirements file is byte-for-byte unchanged
  from the supplied Zorks archive. Confirmed the original Python 3.12.13 Windows
  archive is listed in its upstream release checksum manifest.

Run the offline checks with:

```bash
python3 dev/tests/test_toolchain.py
```

Windows/macOS runtime behavior was checked using shell/archive fixtures on
Linux, not native machines. GPU execution, installation of the full regular or Windows snapshot ComfyUI or
Stable Audio dependency sets, large model downloads and the parent application's
end-to-end behavior were not exercised in this environment. The source archive
contains no full copy of that parent application. See README.md for platform
limits, component installation and migration instructions.

## Older Linux llama.cpp correction

- Validate existing and downloaded llama-server executables before reporting
  success. The previous installer could label a binary installed before finding
  its missing runtime libraries.
- Fall back from an incompatible Linux release binary to a local CPU build of
  the same b10516 source. Downloaded sources are checksum verified.
- Disable OpenSSL and optional Web UI provisioning for the local API server;
  retain the parent application's existing server and model paths.
- Probe C++17 filesystem linking for older compilers and install a local CMake
  when the system version predates 3.14. Keep all build tools outside application
  Python environments. Preserve the previous installation until the new binary
  passes its runtime check.
- Add the tracked script `cli-tools/BUILD-LLAMA-CPP.sh`. Generated source/object
  trees and build tools are ignored under `cli-tools/llama-cpp-build/`.

The local source-build path was also exercised with real b10516 source on Linux
x64 (Ubuntu 24.04 / GCC 13.3) in a checkout path containing spaces. The local
CMake bootstrap ran successfully; llama-server built and executed, `ldd` showed
no libssl/libcrypto dependency, and the local HTTP `/health` endpoint returned
200 with `{"status":"ok"}`. No model inference was exercised. Debian 10 itself
was not available for native validation; GCC 8 filesystem handling and loader
failure recovery were tested with fixtures. Build the source on the target host;
the executable built in this test environment is not included in the archive.

## GCC 8.3 server-schema correction

- Add `cli-tools/patch-llama-cpp-gcc8.py` and invoke it before CMake configuration
  in `BUILD-LLAMA-CPP.sh`. GCC 8.3 cannot perform class template argument
  deduction for the pinned server's `new field_num(...)` expressions. A small
  function-template helper explicitly instantiates the same numeric type and
  preserves reference bindings.
- Apply the patch to fresh or cached b10516 source, guarded by checksums of the
  original and patched file. Preserve unexpected local edits and leave an
  already patched file's timestamp unchanged.
- Keep the existing source archive, release pin and compiled objects so the
  failed build can resume. Windows/macOS binary installations are unaffected.

Using the actual Debian GCC 8.3.0-6 compiler and its C++ headers, reproduced the
original full `server-schema.cpp` failure, then successfully compiled the patched
translation unit to an object file. This compiler check ran on the available
Ubuntu host, not a complete Debian 10 installation. Also resumed the existing
GCC 13.3 build: only the affected translation unit and dependent library/link
steps rebuilt, and the server executed successfully. The updated server's local
HTTP `/health` endpoint returned 200 with `{"status":"ok"}`. No model inference
was exercised.
