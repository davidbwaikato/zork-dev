# Zorks Illustrated development tools

Project-local tools for Windows Git Bash, Linux and macOS. This `dev/` tree
uses the newer Musical Atrium layout: `versions.env`, `INSTALL-*.sh`, separate
activation scripts and `prog-langs/downloads/` / `prog-langs/installed/`.
Zorks-specific tools and model locations remain under `cli-tools/`.

## Apply the replacement

The supplied archive contains a complete **source** tree rooted at `dev/`.
Extract it from the **Zorks Illustrated project root**:

```bash
tar -xzf /path/to/zorks-illustrated-dev-cross-platform.tar.gz
```

Overlaying an existing checkout keeps its `dev/.git` submodule pointer, local
models, installed tools and custom ComfyUI nodes. The archive deliberately does
not contain somebody else's `.git` pointer, downloaded runtimes, upstream
ComfyUI checkout, model weights, download caches, generated path configuration,
Python bytecode or machine-specific databases. Installers recreate these.
It does not alter the parent project's application code or install its npm
packages. For a new checkout, initialise the project's submodules first.

## Install and activate

Run in **Bash**, including on macOS (its default interactive shell may be Zsh):

```bash
./dev/INSTALL-DEV-TOOLS-ALL.sh
source ./dev/SETUP.bash
node --version
pnpm --version
python --version
command -v dfrotz
```

The default installer provisions the full local toolchain, including llama.cpp,
its approximately 1.12 GB command-interpreter model, ComfyUI and its much larger
illustration models, plus a separate Stable Audio Python environment. Stable
Audio model weights are obtained later when used. The installer exits on an
error, so a failed component cannot be mistaken for a complete installation.
Rerun after correcting the reported problem; existing installs are reused.

For a basic server using existing game files and externally provided media/AI
services, install the small core first:

```bash
./dev/INSTALL-DEV-TOOLS-ALL.sh --minimal
source ./dev/SETUP.bash
```

This installs Node.js/pnpm, Python utilities and dfrotz. It does **not** supply
local language interpretation or local illustration/audio generation. Select
components to match the parent application's configuration. For example:

```bash
./dev/INSTALL-DEV-TOOLS-ALL.sh --without-stableaudio
./dev/INSTALL-DEV-TOOLS-ALL.sh --without-models
./dev/INSTALL-DEV-TOOLS-ALL.sh --help
```

All paths are resolved relative to the scripts; installers work when invoked
from another directory, including paths containing spaces. Activation does not
change the working directory or the calling shell's error-handling options.
Repeat activation in every new Bash shell. A service manager must explicitly
source the setup (in Bash) or use the installed executable paths; it does not
inherit an interactive terminal's environment automatically.

## Choose regular packages or the Windows 11 snapshot

The **portable** profile is the default on every operating system. It lets pip
resolve regular PyTorch packages compatible with the running Python, using the
CPU/CUDA index selected from `nvidia-smi` or native macOS packages. The separate
**windows-exact** profile preserves the package versions recorded from the
working Windows 11 Stability Matrix / ComfyUI installation.

| Profile | Installation | Activation | Python environment |
| --- | --- | --- | --- |
| Regular packages | `./dev/INSTALL-DEV-TOOLS-ALL.sh --portable` | `source ./dev/SETUP.bash --portable` | `prog-langs/python-for-zork/` |
| Windows 11 snapshot | `./dev/INSTALL-DEV-TOOLS-ALL.sh --windows-exact` | `source ./dev/SETUP.bash --windows-exact` | `prog-langs/python-for-zork-win11-exact/` |

The Windows snapshot profile requires Windows x64 through Git Bash. It uses
`cli-tools/comfyui_exact_requirements_win64.txt` unchanged, including its exact
`+cu130` package builds, and the official PyTorch CUDA 13.0 wheel index. It skips
the regular torch installer and the subsequent unpinned ComfyUI dependency
pass. Every recorded distribution version is checked after installation,
followed by `pip check` and a small CUDA operation. An installation or validation
failure stops the script; it never substitutes other versions.

This profile restores the original Zorks `dev` Python pin, **3.12.13 / build
20260807**, in its own venv. The regular profile retains **3.12.14 / build
20260901**. The snapshot records Python packages, not the original interpreter
patch version or the whole Stability Matrix application. The Python 3.12.13
choice comes from the supplied original Zorks installer. Full reproduction of
workflow speed also depends on the ComfyUI source/custom nodes, models, driver
and hardware; those are shared or managed separately.

You can install both profiles in the same checkout and activate either one in a
Bash shell. The selected profile and venv name are exported so child scripts
using the existing activation helpers select that same environment. On a new
shell, use the explicit activation command above for the desired profile. For
parallel instances, activate one profile per shell and give the application's
services separate ports. The ComfyUI source and model weights are shared; the
Python dependency environments are separate. Stable Audio keeps its own third
venv and never receives the ComfyUI snapshot.

For a direct component installation instead of the all-tools script:

```bash
ZORKS_COMFYUI_PROFILE=windows-exact ./dev/prog-langs/INSTALL-PYTHON.sh
ZORKS_COMFYUI_PROFILE=windows-exact ./dev/cli-tools/PIP-INSTALL-FOR-COMFYUI.sh
```

The normal `ZORKS_TORCH_BACKEND` overrides apply to the portable profile. The
snapshot profile accepts `auto` or `cu130`; a conflicting CPU/CUDA override is
reported as an error.

## Host requirements

| Host | Language toolchain | dfrotz | Optional ZILF compiler |
| --- | --- | --- | --- |
| Linux x64 / ARM64, glibc | Native archives | Existing PATH executable or local C build | Native archive |
| macOS Apple Silicon | Native archives | Existing PATH executable or local C build | Native archive |
| macOS Intel | Native archives | Existing PATH executable or local C build | Existing ZILF or separate .NET source build |
| Windows x64, Git Bash | Native Windows archives | IF Archive Windows executable | Native archive |
| Windows ARM64, Git Bash | Native Windows archives | x64 executable requires Windows emulation | Existing ZILF or separate source build |

Use Bash 3.2 or later, `tar`, standard Unix utilities, `curl` or `wget`, and a
SHA-256 utility (`sha256sum`, `shasum` or `openssl`). ZIP extraction uses `unzip`,
a ZIP-capable `tar`, or PowerShell under Git Bash. Node's Unix archives need XZ
support. The Linux language downloads target glibc; Alpine/musl is not supported
by this bundle. Release binaries also have their own minimum OS/library versions.

Building dfrotz on Unix requires `make` and a C compiler (`CC` can select it).
No administrator privileges are used by these scripts. Install build tools
separately if the server does not provide them. An existing `dfrotz` on PATH is
accepted. Only Zork recompilation needs ZILF; serving already compiled stories
does not. ZILF 1.9 publishes no Intel macOS or Windows ARM64 archive, so those
hosts report that the optional compiler was skipped and explain the source-build
route. Native ZILF packages include their runtime; .NET is needed only for a
separate source build.

ML package support is narrower than language-runtime support. CPU fallback
allows installation where matching wheels exist; it is not a performance promise
for live media generation. On macOS, PyTorch's native package uses MPS where
available. Windows ARM64 and Intel macOS may need different ML versions or
remote generation services. `imageio-ffmpeg` 0.6.0 has no bundled Windows ARM64
FFmpeg; provide FFmpeg separately there.

## Versions and GPU selection

Language versions are centralised in `versions.env`:

- Node.js 24.18.0 and pnpm 11.25.0 (as in the supplied Musical Atrium setup).
- Regular CPython 3.12.14, python-build-standalone release 20260901.
- Windows snapshot CPython 3.12.13, release 20260807 (original Zorks pins).
- Main venv: `prog-langs/python-for-zork/` (existing parent-project path).
- Windows snapshot venv: `prog-langs/python-for-zork-win11-exact/`.
- Separate optional audio venv: `prog-langs/python-for-stableaudio/`.
- ZILF 1.9.0, Frotz 2.55 source, ComfyUI 0.22.0.

Node.js and Python downloads are verified against upstream SHA-256 manifests.
ZILF native packages, the Unix Frotz source archive and the existing
llama.cpp/model installers use pinned SHA-256 digests. ComfyUI and Windows
dfrotz archives are downloaded over HTTPS but do not have a pinned checksum
in this bundle. In the portable profile, package dependencies are resolved from
their package indexes for the current Python; this is not a fully locked offline
installation. The Windows snapshot profile uses every exact version from
`comfyui_exact_requirements_win64.txt`.

Portable PyTorch selection uses native macOS packages, a conservative CUDA index
supported by the driver reported by `nvidia-smi`, or CPU packages. Pip selects
compatible versions from that index. ComfyUI's later requirements pass constrains
the installed torch/vision/audio versions so that it cannot silently replace the
selected build. Override the backend when configuring a particular server:

```bash
ZORKS_TORCH_BACKEND=cpu ./dev/INSTALL-DEV-TOOLS-ALL.sh --portable --without-stableaudio
ZORKS_TORCH_BACKEND=cu130 ./dev/prog-langs/PIP-INSTALL-PYTORCH.sh
```

Accepted backends: `auto`, `cpu`, `cu126`, `cu128`, `cu130` (`mps` is also accepted
on macOS). Stable Audio retains the older separate 2.7.1 torch/audio family and
uses CUDA 12.8 at most, CPU or macOS packages. It no longer forces CUDA 12.8 on
every OS or opens an interactive Hugging Face login during unattended installs.
Gated weights still require model terms to be accepted and credentials supplied
through `HF_TOKEN` or a separate `hf auth login`.

Changing Python pins preserves mismatched venvs/installations with an
`.incomplete.TIMESTAMP` suffix before rebuilding them. Existing environments
therefore remain available, but packages must be installed into the new venv.
Do not copy a venv or installed binaries between operating systems.

## Install components individually

```bash
./dev/prog-langs/INSTALL-NODEJS.sh
./dev/prog-langs/INSTALL-PYTHON.sh
./dev/cli-tools/INSTALL-DFROTZ.sh
./dev/prog-langs/INSTALL-ZILF.sh
./dev/cli-tools/GET-LLAMA-CPP.sh
./dev/cli-tools/GET-LLAMA-CPP-MODEL.sh
./dev/cli-tools/INSTALL-COMFYUI.sh
./dev/cli-tools/PIP-INSTALL-FOR-COMFYUI.sh
./dev/cli-tools/DOWNLOAD-MODELS-FOR-COMFYUI.sh
VENV_DIR=python-for-stableaudio ./dev/prog-langs/INSTALL-PYTHON.sh
./dev/prog-langs/PIP-INSTALL-STABLEAUDIO.sh
```

The all-tools installer also enables Corepack and provisions pinned pnpm after
Node installation. The Node-only installer does not provision pnpm.

Local llama.cpp paths and all `ZUI_*` variables supplied by the older
`cli-tools/SETUP.bash` are retained. Defaults are configured only when the local
server and model are present. As before, the parent project's run script starts
the server; activation itself starts no processes.

## Older Linux hosts and llama.cpp

The official Ubuntu llama.cpp binary can require newer OpenSSL, glibc or C++
runtime libraries than an older Linux installation provides. A Debian 10
`libssl.so.3: cannot open shared object file` error is one example.

`cli-tools/GET-LLAMA-CPP.sh` now runs `llama-server --version` before accepting
an existing installation or publishing a downloaded one. On Linux its default
`auto` mode falls back to a local **CPU source build of the same b10516 release**
when the release binary cannot run. Windows/macOS retain their binary routes.
A failing runtime check is no longer reported as a successful installation.

To recover the already downloaded, incompatible installation, extract the
updated dev archive over the project and run from the application root:

```bash
ZORKS_LLAMA_CPP_INSTALL_MODE=source ./dev/cli-tools/GET-LLAMA-CPP.sh
./dev/INSTALL-DEV-TOOLS-ALL.sh --portable
```

The source builder needs `make` and working C/C++17 compilers (`CC` and `CXX`
can select them). It probes whether an older compiler needs `-lstdc++fs` for
C++17 filesystem support. It uses an existing CMake 3.14+ or installs pinned
CMake 3.31.6 in an isolated build-tools venv using the already installed regular
project Python. It does not change system packages or the application's Python
package profiles. The source tarball is pinned and SHA-256 verified.

GCC 8.3 also fails to deduce `field_num<T>` in the pinned server's
`new field_num(...)` expressions. The source builder automatically applies
`cli-tools/patch-llama-cpp-gcc8.py`, a small compatibility patch that supplies
the same numeric type through a function template. The patch checks the source
file's checksum and preserves unexpected local edits rather than overwriting
them. It also applies to an existing cached source tree. Rerunning the commands
above after this compiler error reuses the compiled objects; keep the source and
build directories in place. Later runs leave the patched file's timestamp
unchanged so it does not trigger another recompilation.

The build sets `LLAMA_OPENSSL=OFF`, uses static llama/ggml libraries, and disables
CUDA and optional Web UI provisioning/downloads. It links against the building
host's system libraries. The resulting server retains its local HTTP API; the
separate model downloader still obtains the pinned GGUF through curl. Direct
HTTPS service and built-in HTTPS model downloads are unavailable in this build.
Zorks uses its own interface and calls the local HTTP endpoint.

The replacement is published only after it runs successfully. An old
installation is kept beneath `cli-tools/llama-cpp-build/previous-install-*`.
Source, object files and local build tools also remain under the ignored
`cli-tools/llama-cpp-build/` directory so an interrupted build can be resumed.
The installation path remains `cli-tools/llama-cpp/`; parent run scripts and
model paths remain unchanged.

Settings:

- `ZORKS_LLAMA_CPP_INSTALL_MODE=auto` (default): validate a binary, build locally
  on Linux if it cannot run.
- `ZORKS_LLAMA_CPP_INSTALL_MODE=binary`: report binary compatibility failures
  without a source build.
- `ZORKS_LLAMA_CPP_INSTALL_MODE=source`: explicitly run the Linux source builder.
- `ZORKS_LLAMA_BUILD_JOBS=2` (default): cap compiler parallelism; increase if the
  machine has sufficient CPU and memory.
- `ZORKS_LLAMA_CMAKE=/path/to/cmake`: explicitly choose CMake 3.14+.

The downloaded source is saved as
`cli-tools/llama-cpp-downloads/llama.cpp-b10516.tar.gz`. Like other download
caches it is ignored by default; it can be retained deliberately with `git add -f`
if archiving that source tarball in the dev repository is desired.

## Canonical filenames and compatibility

| Older entry point | Canonical implementation |
| --- | --- |
| `GET-DEV-TOOLS-ALL.sh` | `INSTALL-DEV-TOOLS-ALL.sh` |
| `prog-langs/GET-NODEJS-WIN64.sh` | `prog-langs/INSTALL-NODEJS.sh` |
| `prog-langs/GET-VENV-PYTHON.sh` | `prog-langs/INSTALL-PYTHON.sh` |
| `prog-langs/GET-ZILF-WIN64.sh` | `prog-langs/INSTALL-ZILF.sh` |
| `cli-tools/GET-DFROTZ-WIN64.sh` | `cli-tools/INSTALL-DFROTZ.sh` |
| `cli-tools/GET-COMFYUI.sh` | `cli-tools/INSTALL-COMFYUI.sh` |
| `ACTIVATE-PYTHON.bash` | `prog-langs/ACTIVATE-PYTHON.bash` |

These old names remain small forwarding wrappers, so existing parent scripts
continue to find them. The misspelled `PIP-INSTALL-STLABLEAUDIO.sh` is also a
forwarder. The historical experimental
`PIP-INSTALL-PYTORCH--DIFFUSERS_pytorch213.sh` forwards to the maintained PyTorch
installer; it no longer attempts the inconsistent experimental version mix.
The obsolete Unix ZILF source-build helper is replaced by native package
installation where available.

After reviewing the update, commit it in the **dev submodule's own branch**,
push that branch, then commit the new submodule revision in the parent project.
This archive supplies source files, not Git history. It includes executable file
modes and LF line endings; the included `.gitattributes` preserves line endings.
