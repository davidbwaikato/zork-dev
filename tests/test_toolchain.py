#!/usr/bin/env python3
"""Offline behavior checks; run: python3 dev/tests/test_toolchain.py.

Native Windows/macOS executables are represented by fixtures on Linux. These
checks test host selection, archive verification and shell integration; they do
not substitute for native platform tests or live ML package installation.
"""
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest
import zipfile

SOURCE = Path(__file__).resolve().parents[1]
HOSTS = [
    ('Linux', 'x86_64', 'linux', 'x64', 'x86_64-unknown-linux-gnu'),
    ('Linux', 'aarch64', 'linux', 'arm64', 'aarch64-unknown-linux-gnu'),
    ('Darwin', 'x86_64', 'darwin', 'x64', 'x86_64-apple-darwin'),
    ('Darwin', 'arm64', 'darwin', 'arm64', 'aarch64-apple-darwin'),
    ('MINGW64_NT-10.0', 'x86_64', 'win', 'x64', 'x86_64-pc-windows-msvc'),
    ('MSYS_NT-10.0', 'aarch64', 'win', 'arm64', 'aarch64-pc-windows-msvc'),
]


def executable(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)


def make_archive(path, files):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix == '.zip':
        with zipfile.ZipFile(path, 'w') as archive:
            for name, data in files.items():
                info = zipfile.ZipInfo(name)
                info.external_attr = 0o100755 << 16
                archive.writestr(info, data)
    else:
        with tarfile.open(path, 'w:xz' if path.name.endswith('.xz') else 'w:gz') as archive:
            for name, data in files.items():
                raw = data.encode()
                info = tarfile.TarInfo(name)
                info.size = len(raw)
                info.mode = 0o755
                archive.addfile(info, io.BytesIO(raw))
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ToolchainTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='zorks test & ')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.dev = self.base / 'project with spaces & symbols' / 'dev'
        shutil.copytree(SOURCE, self.dev, ignore=shutil.ignore_patterns(
            '__pycache__', 'downloads', 'installed', 'python-for-*',
            'ComfyUI', 'llama-cpp', 'llama-cpp-downloads', 'llama-cpp-models', 'llama-cpp-build'))
        self.bin = self.base / 'mock-bin'
        self.bin.mkdir()
        self.env = dict(os.environ)
        for key in ('VENV_DIR', 'VIRTUAL_ENV', 'ZORKS_PYTHON_VENV', 'ZORKS_TORCH_BACKEND', 'ZORKS_DEV_COMMON_LOADED', 'ZORKS_COMFYUI_PROFILE', 'ZORKS_TORCH_PROFILE'):
            self.env.pop(key, None)
        self.env.update(PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        # A missing download fails fast; no test should depend on the network.
        executable(self.bin / 'curl', '#!/usr/bin/env bash\nexit 91\n')
        executable(self.bin / 'nvidia-smi', '#!/usr/bin/env bash\nexit 1\n')

    def host(self, kernel, arch):
        executable(self.bin / 'uname', '#!/usr/bin/env bash\ncase "$1" in\n-s) echo "' + kernel + '";;\n-m) echo "' + arch + '";;\nesac\n')

    def run_script(self, name, *args, success=True):
        result = subprocess.run(['bash', str(self.dev / name), *args],
                                cwd=self.base, env=self.env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def seed_node(self, os_name, arch):
        dist = f'node-v24.18.0-{os_name}-{arch}'
        relative = 'node.exe' if os_name == 'win' else 'bin/node'
        archive = self.dev / 'prog-langs/downloads/nodejs' / (dist + ('.zip' if os_name == 'win' else '.tar.xz'))
        digest = make_archive(archive, {f'{dist}/{relative}': '#!/usr/bin/env bash\necho v24.18.0\n'})
        (archive.parent / 'SHASUMS256-v24.18.0.txt').write_text(f'{digest}  {archive.name}\n')
        return archive

    def seed_python(self, os_name, target, version="3.12.14", release="20260901"):
        relative = 'python.exe' if os_name == 'win' else 'bin/python3'
        venv_rel = 'Scripts/python.exe' if os_name == 'win' else 'bin/python'
        body = '''#!/usr/bin/env bash
if [[ -n "${ZORKS_TEST_LOG:-}" ]]; then printf '%s\\n' "$*" >> "$ZORKS_TEST_LOG"; fi
if [[ "$1" == -c ]]; then echo @VERSION@
elif [[ "$1" == -m && "$2" == venv ]]; then
  mkdir -p "$3/''' + venv_rel.rsplit('/', 1)[0] + '''"
  cp "$0" "$3/''' + venv_rel + '''"
elif [[ "$1" == -m && "$2" == pip ]]; then exit 0
else exit 3
fi
'''
        body = body.replace('@VERSION@', version)
        archive = self.dev / 'prog-langs/downloads/python' / f'cpython-{version}+{release}-{target}-install_only_stripped.tar.gz'
        digest = make_archive(archive, {f'python/{relative}': body})
        (archive.parent / f'SHA256SUMS-{release}.txt').write_text(f'{digest}  {archive.name}\n')
        return archive

    def test_host_detection(self):
        for kernel, arch, os_name, normal_arch, _ in HOSTS:
            with self.subTest(kernel=kernel, arch=arch):
                self.host(kernel, arch)
                result = subprocess.run(['bash', '-c', 'source "$1"; zorks_dev_detect_host; printf "%s:%s" "$ZORKS_DEV_OS" "$ZORKS_DEV_ARCH"', 'test', str(self.dev/'prog-langs/_common.bash')], env=self.env, capture_output=True, text=True, check=True)
                self.assertEqual(result.stdout, os_name + ':' + normal_arch)

    def test_unknown_host_fails(self):
        self.host('Plan9', 'x86_64')
        result = self.run_script('prog-langs/INSTALL-NODEJS.sh', success=False)
        self.assertIn('Unsupported operating system', result.stdout)

    def test_node_install_and_reuse_for_six_hosts(self):
        for kernel, arch, os_name, normal_arch, _ in HOSTS:
            with self.subTest(kernel=kernel, arch=arch):
                self.host(kernel, arch)
                self.seed_node(os_name, normal_arch)
                self.run_script('prog-langs/INSTALL-NODEJS.sh')
                self.assertIn('already installed', self.run_script('prog-langs/INSTALL-NODEJS.sh').stdout)

    def test_python_install_and_reuse_for_six_hosts(self):
        for kernel, arch, os_name, normal_arch, target in HOSTS:
            with self.subTest(kernel=kernel, arch=arch):
                self.host(kernel, arch)
                self.seed_python(os_name, target)
                self.env['VENV_DIR'] = 'fixture-' + os_name + '-' + normal_arch
                self.run_script('prog-langs/INSTALL-PYTHON.sh')
                self.run_script('prog-langs/INSTALL-PYTHON.sh')
                relative = 'Scripts/python.exe' if os_name == 'win' else 'bin/python'
                self.assertTrue((self.dev / 'prog-langs' / self.env['VENV_DIR'] / relative).is_file())

    def test_bad_node_cache_cannot_be_installed(self):
        self.host('Linux', 'x86_64')
        archive = self.seed_node('linux', 'x64')
        archive.write_bytes(b'corrupt archive')
        result = self.run_script('prog-langs/INSTALL-NODEJS.sh', success=False)
        self.assertIn('Checksum mismatch', result.stdout)
        self.assertFalse((self.dev / 'prog-langs/installed/node-v24.18.0-linux-x64').exists())
        self.assertFalse(list(archive.parent.glob('*.part.*')))

    def test_bad_python_cache_cannot_be_installed(self):
        self.host('Linux', 'x86_64')
        archive = self.seed_python('linux', HOSTS[0][-1])
        (archive.parent/'SHA256SUMS-20260901.txt').write_text('0'*64 + '  ' + archive.name + '\n')
        result = self.run_script('prog-langs/INSTALL-PYTHON.sh', success=False)
        self.assertIn('SHA-256 mismatch', result.stdout)
        self.assertFalse((self.dev/'prog-langs/python-for-zork').exists())

    def test_activation_preserves_cwd_options_and_is_idempotent(self):
        self.host('Linux', 'x86_64')
        self.seed_node('linux', 'x64')
        self.run_script('prog-langs/INSTALL-NODEJS.sh')
        venv = self.dev/'prog-langs/python-for-zork'
        executable(venv/'bin/python', '#!/usr/bin/env bash\necho Python 3.12.14\n')
        (venv/'bin/activate').write_text('export VIRTUAL_ENV="' + str(venv) + '"\n_OLD_VIRTUAL_PATH="$PATH"\nexport PATH="$VIRTUAL_ENV/bin:$PATH"\ndeactivate() { PATH="$_OLD_VIRTUAL_PATH"; unset VIRTUAL_ENV; }\n')
        executable(self.dev/'cli-tools/dfrotz-linux-x64/dfrotz', '#!/usr/bin/env bash\nexit 0\n')
        script = '''set -euo pipefail
before_pwd="$PWD"; before_options="$-"
source "$1"
source "$1"
[[ "$before_pwd" == "$PWD" && "$before_options" == "$-" ]]
[[ "$(command -v node)" == "$ZORKS_DEV_NODE_BIN_DIR/node" ]]
[[ "$(command -v python)" == "$VIRTUAL_ENV/bin/python" ]]
python_count=0; node_count=0
old_ifs="$IFS"; IFS=:
for directory in $PATH; do
  [[ "$directory" != "$VIRTUAL_ENV/bin" ]] || python_count=$((python_count+1))
  [[ "$directory" != "$ZORKS_DEV_NODE_BIN_DIR" ]] || node_count=$((node_count+1))
done
IFS="$old_ifs"
[[ "$python_count" == 1 && "$node_count" == 1 ]]
'''
        result = subprocess.run(['bash', '-c', script, 'test', str(self.dev/'SETUP.bash')], cwd=self.base, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_switching_checkouts_keeps_new_node_and_python(self):
        self.host('Linux', 'x86_64')
        self.seed_node('linux', 'x64')
        self.run_script('prog-langs/INSTALL-NODEJS.sh')
        second = self.base/'another checkout'/ 'dev'
        shutil.copytree(self.dev, second)
        for root in (self.dev, second):
            venv = root/'prog-langs/python-for-zork'
            executable(venv/'bin/python', '#!/usr/bin/env bash\necho Python 3.12.14\n')
            (venv/'bin/activate').write_text('export VIRTUAL_ENV="' + str(venv) + '"\n_OLD_VIRTUAL_PATH="$PATH"\nexport PATH="$VIRTUAL_ENV/bin:$PATH"\ndeactivate() { PATH="$_OLD_VIRTUAL_PATH"; unset VIRTUAL_ENV; }\n')
            executable(root/'cli-tools/dfrotz-linux-x64/dfrotz', '#!/usr/bin/env bash\nexit 0\n')
        script = 'set -euo pipefail; source "$1/SETUP.bash"; source "$2/SETUP.bash"; [[ "$(command -v node)" == "$2/prog-langs/installed/node-v24.18.0-linux-x64/bin/node" ]]; [[ "$(command -v python)" == "$2/prog-langs/python-for-zork/bin/python" ]]'
        result=subprocess.run(['bash','-c',script,'test',str(self.dev),str(second)],env=self.env,capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_setup_execution_and_missing_runtime_fail(self):
        self.run_script('SETUP.bash', success=False)
        result = subprocess.run(['bash', '-c', 'source "$1"', 'test', str(self.dev/'SETUP.bash')], env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)

    def test_legacy_all_tools_wrapper_and_invalid_option(self):
        self.assertIn('Usage:', self.run_script('GET-DEV-TOOLS-ALL.sh', '--help').stdout)
        self.run_script('GET-DEV-TOOLS-ALL.sh', '--not-a-valid-option', success=False)

    def test_torch_backend_selection(self):
        python = self.dev/'prog-langs/python-for-zork/bin/python'
        log = self.base/'pip calls.txt'
        self.env['ZORKS_TEST_LOG'] = str(log)
        executable(python, '#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$ZORKS_TEST_LOG"\n')
        for kernel, cuda, expected in [('Linux', None, 'cpu'), ('Linux', '13.0', 'cu130'), ('Linux', '12.9', 'cu128'), ('Linux', '12.6', 'cu126'), ('Darwin', None, None)]:
            with self.subTest(kernel=kernel, cuda=cuda):
                self.host(kernel, 'arm64' if kernel=='Darwin' else 'x86_64')
                if cuda:
                    executable(self.bin/'nvidia-smi', '#!/usr/bin/env bash\necho "CUDA Version: ' + cuda + '"\n')
                else:
                    executable(self.bin/'nvidia-smi', '#!/usr/bin/env bash\nexit 1\n')
                log.write_text('')
                self.run_script('prog-langs/PIP-INSTALL-PYTORCH.sh')
                calls=log.read_text()
                self.assertIn('pip install torch torchvision torchaudio',calls)
                if expected: self.assertIn('https://download.pytorch.org/whl/'+expected,calls)
                else: self.assertNotIn('--index-url',calls)

    def test_failed_pip_is_reported(self):
        self.host('Linux', 'x86_64')
        executable(self.dev/'prog-langs/python-for-zork/bin/python', '#!/usr/bin/env bash\nexit 23\n')
        self.env['ZORKS_TORCH_BACKEND']='cpu'
        result=self.run_script('prog-langs/PIP-INSTALL-PYTORCH.sh', success=False)
        self.assertEqual(result.returncode,23)

    def mock_comfy_python(self, venv):
        log = self.base/'profile pip calls.txt'
        log.write_text('')
        self.env['ZORKS_TEST_LOG'] = str(log)
        executable(self.dev/'prog-langs'/venv/'Scripts/python.exe', '''#!/usr/bin/env bash
printf '%s|%s\n' "$0" "$*" >> "$ZORKS_TEST_LOG"
if [[ "$*" == '-m pip freeze' ]]; then
  printf 'torch==2.12.0+cu130\ntorchvision==0.27.0+cu130\ntorchaudio==2.11.0+cu130\n'
fi
if [[ "${ZORKS_TEST_FAIL_PIP:-}" == yes && "$1" == -m && "$2" == pip && "$3" == install ]]; then exit 23; fi
exit 0
''')
        requirements = self.dev/'cli-tools/ComfyUI/requirements.txt'
        requirements.parent.mkdir(parents=True, exist_ok=True)
        requirements.write_text('torch\n')
        return log

    def test_windows_regular_is_default(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        log = self.mock_comfy_python('python-for-zork')
        self.run_script('cli-tools/PIP-INSTALL-FOR-COMFYUI.sh')
        calls = log.read_text()
        self.assertIn('pip install torch torchvision torchaudio', calls)
        self.assertNotIn('comfyui_exact_requirements_win64.txt', calls)
        self.assertNotIn('python-for-zork-win11-exact', calls)

    def test_windows_exact_uses_snapshot_and_separate_venv(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.env['ZORKS_COMFYUI_PROFILE'] = 'windows-exact'
        log = self.mock_comfy_python('python-for-zork-win11-exact')
        snapshot = self.dev/'cli-tools/comfyui_exact_requirements_win64.txt'
        before = snapshot.read_bytes()
        self.run_script('cli-tools/PIP-INSTALL-FOR-COMFYUI.sh')
        calls = log.read_text()
        self.assertIn('pip install --extra-index-url https://download.pytorch.org/whl/cu130 -r ' + str(snapshot), calls)
        self.assertIn('python-for-zork-win11-exact/Scripts/python.exe', calls)
        self.assertNotIn('pip install torch torchvision torchaudio', calls)
        self.assertNotIn('ComfyUI/requirements.txt', calls)
        self.assertNotIn('pip install PyOpenGL', calls)
        self.assertNotIn('--no-deps', calls)
        self.assertEqual(snapshot.read_bytes(), before)
        self.assertEqual(hashlib.sha256(snapshot.read_text().encode()).hexdigest(),
                         '30f8abff31a3e7372125f178e4e5dafb46cfbc3cbc2d7a2b0f7bf8e31d493d8a')

    def test_standalone_torch_honours_exact_profile(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.env['ZORKS_COMFYUI_PROFILE'] = 'windows-exact'
        log = self.mock_comfy_python('python-for-zork-win11-exact')
        self.run_script('prog-langs/PIP-INSTALL-PYTORCH.sh')
        self.assertIn('comfyui_exact_requirements_win64.txt', log.read_text())
        self.assertNotIn('pip install torch torchvision torchaudio', log.read_text())

    def test_exact_profile_rejects_other_hosts_and_backends(self):
        self.host('Linux', 'x86_64')
        result = self.run_script('INSTALL-DEV-TOOLS-ALL.sh', '--windows-exact', success=False)
        self.assertIn('Windows x64', result.stdout)
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.env['ZORKS_TORCH_BACKEND'] = 'cpu'
        result = self.run_script('INSTALL-DEV-TOOLS-ALL.sh', '--windows-exact', success=False)
        self.assertIn('pins CUDA 13.0', result.stdout)

    def test_exact_install_failure_does_not_use_regular_packages(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.env.update(ZORKS_COMFYUI_PROFILE='windows-exact', ZORKS_TEST_FAIL_PIP='yes')
        log = self.mock_comfy_python('python-for-zork-win11-exact')
        result = self.run_script('cli-tools/PIP-INSTALL-FOR-COMFYUI.sh', success=False)
        self.assertEqual(result.returncode, 23)
        self.assertNotIn('pip install torch torchvision torchaudio', log.read_text())

    def test_stable_audio_stays_independent_of_snapshot(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.env.update(ZORKS_COMFYUI_PROFILE='windows-exact',
                        VENV_DIR='python-for-stableaudio', ZORKS_TORCH_PROFILE='stableaudio')
        executable(self.bin/'nvidia-smi', '#!/usr/bin/env bash\necho "CUDA Version: 13.0"\n')
        log = self.mock_comfy_python('python-for-stableaudio')
        self.run_script('prog-langs/PIP-INSTALL-PYTORCH.sh')
        calls=log.read_text()
        self.assertIn('torch==2.7.1 torchaudio==2.7.1', calls)
        self.assertIn('https://download.pytorch.org/whl/cu128', calls)
        self.assertNotIn('comfyui_exact_requirements_win64.txt', calls)

    def test_exact_python_keeps_regular_venv_and_original_python_pin(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.seed_python('win', HOSTS[4][-1])
        self.run_script('prog-langs/INSTALL-PYTHON.sh')
        regular=self.dev/'prog-langs/python-for-zork/Scripts/python.exe'
        original=regular.read_bytes()
        self.env['ZORKS_COMFYUI_PROFILE']='windows-exact'
        self.seed_python('win', HOSTS[4][-1], '3.12.13', '20260807')
        log=self.base/'python calls.txt'
        self.env['ZORKS_TEST_LOG']=str(log)
        self.run_script('prog-langs/INSTALL-PYTHON.sh')
        exact=self.dev/'prog-langs/python-for-zork-win11-exact/Scripts/python.exe'
        self.assertTrue(exact.exists())
        self.assertIn('echo 3.12.13',exact.read_text())
        self.assertEqual(regular.read_bytes(),original)
        self.assertNotIn('pip install -r',log.read_text())

    def test_explicit_profile_overrides_inherited_default_venv_name(self):
        for profile, previous, expected in [
            ('portable','python-for-zork-win11-exact','python-for-zork'),
            ('windows-exact','python-for-zork','python-for-zork-win11-exact')]:
            with self.subTest(profile=profile):
                env=dict(self.env,ZORKS_COMFYUI_PROFILE=profile,VENV_DIR=previous)
                result=subprocess.run(['bash','-c','source "$1"; printf "%s" "$ZORKS_PYTHON_VENV"','test',str(self.dev/'versions.env')],env=env,capture_output=True,text=True,check=True)
                self.assertEqual(result.stdout,expected)

    def test_activation_switches_regular_and_exact_profiles(self):
        self.host('MINGW64_NT-10.0', 'x86_64')
        self.seed_node('win','x64')
        self.run_script('prog-langs/INSTALL-NODEJS.sh')
        for name in ('python-for-zork','python-for-zork-win11-exact'):
            venv=self.dev/'prog-langs'/name
            executable(venv/'Scripts/python', '#!/usr/bin/env bash\necho Python\n')
            (venv/'Scripts/activate').write_text('export VIRTUAL_ENV="'+str(venv)+'"\n_OLD_VIRTUAL_PATH="$PATH"\nexport PATH="$VIRTUAL_ENV/Scripts:$PATH"\ndeactivate() { PATH="$_OLD_VIRTUAL_PATH"; unset VIRTUAL_ENV; }\n')
        executable(self.dev/'cli-tools/dfrotz-win64/dfrotz.exe', '#!/usr/bin/env bash\nexit 0\n')
        script='''set -euo pipefail
source "$1/SETUP.bash" --portable
[[ "$ZORKS_PYTHON_VENV" == python-for-zork && "$ZORKS_PYTHON_VERSION" == 3.12.14 ]]
source "$1/SETUP.bash" --windows-exact
[[ "$ZORKS_PYTHON_VENV" == python-for-zork-win11-exact && "$ZORKS_PYTHON_VERSION" == 3.12.13 ]]
[[ "$(command -v python)" == "$1/prog-langs/python-for-zork-win11-exact/Scripts/python" ]]
source "$1/SETUP.bash" --portable
[[ "$ZORKS_PYTHON_VENV" == python-for-zork && "$ZORKS_PYTHON_VERSION" == 3.12.14 ]]
[[ "$(command -v python)" == "$1/prog-langs/python-for-zork/Scripts/python" ]]
'''
        result=subprocess.run(['bash','-c',script,'test',str(self.dev)], env=self.env, capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)



    def test_existing_llama_runtime_is_validated(self):
        self.host('Linux','x86_64')
        executable(self.dev/'cli-tools/llama-cpp/llama-server', '#!/usr/bin/env bash\necho working-llama\n')
        executable(self.dev/'cli-tools/BUILD-LLAMA-CPP.sh', '#!/usr/bin/env bash\nexit 42\n')
        result=self.run_script('cli-tools/GET-LLAMA-CPP.sh')
        self.assertIn('runnable',result.stdout)

    def test_existing_broken_linux_llama_uses_source_fallback(self):
        self.host('Linux','x86_64')
        server=self.dev/'cli-tools/llama-cpp/llama-server'
        original='#!/usr/bin/env bash\necho "libssl.so.3 not found" >&2\nexit 127\n'
        executable(server,original)
        executable(self.dev/'cli-tools/BUILD-LLAMA-CPP.sh', '#!/usr/bin/env bash\necho SOURCE-FALLBACK\n')
        result=self.run_script('cli-tools/GET-LLAMA-CPP.sh')
        self.assertIn('SOURCE-FALLBACK',result.stdout)
        self.assertNotIn('Already installed',result.stdout)
        self.assertEqual(server.read_text(),original)

    def test_binary_mode_reports_existing_loader_failure(self):
        self.host('Linux','x86_64')
        self.env['ZORKS_LLAMA_CPP_INSTALL_MODE']='binary'
        executable(self.dev/'cli-tools/llama-cpp/llama-server', '#!/usr/bin/env bash\nexit 127\n')
        executable(self.dev/'cli-tools/BUILD-LLAMA-CPP.sh', '#!/usr/bin/env bash\necho SHOULD-NOT-RUN\n')
        result=self.run_script('cli-tools/GET-LLAMA-CPP.sh',success=False)
        self.assertNotIn('SHOULD-NOT-RUN',result.stdout)
        self.assertIn('failed its runtime check',result.stdout)

    def test_downloaded_broken_llama_is_not_published(self):
        self.host('Linux','x86_64')
        archive=self.dev/'cli-tools/llama-cpp-downloads/llama-b10516-bin-ubuntu-x64.tar.gz'
        digest=make_archive(archive,{'package/llama-server':'#!/usr/bin/env bash\necho "libssl.so.3 not found" >&2\nexit 127\n'})
        script=self.dev/'cli-tools/GET-LLAMA-CPP.sh'
        script.write_text(script.read_text().replace('f263a91280471b4c33c4999d7c76259c0f3a0a53a0b3e692b2c0b84380137a35',digest))
        executable(self.dev/'cli-tools/BUILD-LLAMA-CPP.sh', '#!/usr/bin/env bash\necho SOURCE-FALLBACK\n')
        result=self.run_script('cli-tools/GET-LLAMA-CPP.sh')
        self.assertIn('SOURCE-FALLBACK',result.stdout)
        self.assertFalse((self.dev/'cli-tools/llama-cpp').exists())
        self.assertFalse(list((self.dev/'cli-tools').glob('.llama-cpp-install.*')))

    def mock_llama_source_build(self):
        self.host('Linux','x86_64')
        log=self.base/'cmake calls.txt'
        self.env['ZORKS_TEST_CMAKE_LOG']=str(log)
        # This fixture has no upstream C++ source. Exercise patch dispatch here;
        # the real patch's content/type/idempotence checks are tested below.
        (self.dev/'cli-tools/patch-llama-cpp-gcc8.py').write_text(
            'import os\nwith open(os.environ["ZORKS_TEST_CMAKE_LOG"], "a") as log:\n'
            '    log.write("APPLY-GCC8-PATCH\\n")\n')
        self.env['CC']=str(self.bin/'cc')
        self.env['CXX']=str(self.bin/'c++')
        executable(self.bin/'cc', '#!/usr/bin/env bash\nexit 0\n')
        executable(self.bin/'c++', '''#!/usr/bin/env bash
if [[ "${ZORKS_TEST_REQUIRE_FILESYSTEM:-}" == yes && "$*" != *-lstdc++fs* ]]; then exit 1; fi
while [[ $# -gt 0 ]]; do
  if [[ "$1" == -o ]]; then shift; printf '#!/usr/bin/env bash\\nexit 0\\n' > "$1"; chmod +x "$1"; exit 0; fi
  shift
done
exit 0
''')
        executable(self.bin/'cmake', '''#!/usr/bin/env bash
if [[ "$1" == --version ]]; then echo 'cmake version 3.31.6'; exit 0; fi
printf '%s\\n' "$*" >> "$ZORKS_TEST_CMAKE_LOG"
if [[ "$1" == --build ]]; then
  if [[ "${ZORKS_TEST_BUILD_FAIL:-}" == yes ]]; then exit 23; fi
  mkdir -p "$2/bin"
  printf '#!/usr/bin/env bash\\necho source-built-llama\\n' > "$2/bin/llama-server"
  chmod +x "$2/bin/llama-server"
fi
''')
        archive=self.dev/'cli-tools/llama-cpp-downloads/llama.cpp-b10516.tar.gz'
        digest=make_archive(archive,{'llama.cpp-b10516/CMakeLists.txt':'fixture\n','llama.cpp-b10516/LICENSE':'fixture license\n'})
        config=self.dev/'cli-tools/_llama_cpp_env.bash'
        config.write_text(config.read_text().replace('bd13fa381488aa59ae4081aca24d368a956ad6e393c54931510a94d240590e33',digest))
        return log,archive

    def test_source_build_disables_ssl_and_handles_gcc8_filesystem(self):
        log,_=self.mock_llama_source_build()
        self.env['ZORKS_TEST_REQUIRE_FILESYSTEM']='yes'
        executable(self.dev/'cli-tools/llama-cpp/llama-server', '#!/usr/bin/env bash\nexit 127\n')
        self.run_script('cli-tools/BUILD-LLAMA-CPP.sh')
        calls=log.read_text()
        self.assertTrue(calls.startswith('APPLY-GCC8-PATCH\n'), calls)
        for option in ('-DLLAMA_OPENSSL=OFF','-DBUILD_SHARED_LIBS=OFF','-DGGML_CUDA=OFF',
                       '-DLLAMA_BUILD_UI=OFF','-DLLAMA_USE_PREBUILT_UI=OFF',
                       '-DCMAKE_CXX_STANDARD_LIBRARIES=-lstdc++fs','--target llama-server --parallel 2'):
            self.assertIn(option,calls)
        installed=self.dev/'cli-tools/llama-cpp/llama-server'
        self.assertIn('source-built-llama',installed.read_text())
        self.assertTrue(list((self.dev/'cli-tools/llama-cpp-build').glob('previous-install-*')))

    def test_failed_source_build_preserves_existing_install(self):
        self.mock_llama_source_build()
        self.env['ZORKS_TEST_BUILD_FAIL']='yes'
        server=self.dev/'cli-tools/llama-cpp/llama-server'
        old='#!/usr/bin/env bash\necho existing-install\n'
        executable(server,old)
        self.run_script('cli-tools/BUILD-LLAMA-CPP.sh',success=False)
        self.assertEqual(server.read_text(),old)

    def test_source_checksum_failure_preserves_existing_install(self):
        _,archive=self.mock_llama_source_build()
        archive.write_bytes(b'bad source cache')
        server=self.dev/'cli-tools/llama-cpp/llama-server'
        old='#!/usr/bin/env bash\necho existing-install\n'
        executable(server,old)
        result=self.run_script('cli-tools/BUILD-LLAMA-CPP.sh',success=False)
        self.assertIn('checksum mismatch',result.stdout)
        self.assertEqual(server.read_text(),old)

    def test_forced_source_mode_rejects_non_linux(self):
        self.host('Darwin','arm64')
        self.env['ZORKS_LLAMA_CPP_INSTALL_MODE']='source'
        result=self.run_script('cli-tools/GET-LLAMA-CPP.sh',success=False)
        self.assertIn('supports Linux only',result.stdout)

    def load_llama_schema_patcher(self):
        spec=importlib.util.spec_from_file_location(
            'llama_schema_patcher', self.dev/'cli-tools/patch-llama-cpp-gcc8.py')
        module=importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_schema_patch_is_repeatable_without_rewriting_cached_source(self):
        patcher=self.load_llama_schema_patcher()
        source=self.base/'upstream source'
        schema=source/'tools/server/server-schema.cpp'
        schema.parent.mkdir(parents=True)
        original=('namespace server_schema {\n' +
                  'new field_num("number", value);\n'*42 + '}\n')
        patched=patcher.compatible_text(original)
        patcher.ORIGINAL_SHA256=hashlib.sha256(original.encode()).hexdigest()
        patcher.PATCHED_SHA256=hashlib.sha256(patched.encode()).hexdigest()
        schema.write_text(original)
        self.assertTrue(patcher.patch_schema(source))
        self.assertEqual(schema.read_text(),patched)
        os.utime(schema, ns=(1234567890000000000,1234567890000000000))
        before=schema.stat().st_mtime_ns
        self.assertFalse(patcher.patch_schema(source))
        self.assertEqual(schema.stat().st_mtime_ns,before)
        self.assertEqual(schema.read_text(),patched)

    def test_schema_patch_rejects_unexpected_source_and_layout(self):
        patcher=self.load_llama_schema_patcher()
        source=self.base/'modified source'
        schema=source/'tools/server/server-schema.cpp'
        schema.parent.mkdir(parents=True)
        original='preserve local edits\n'
        schema.write_text(original)
        with self.assertRaisesRegex(ValueError,'preserving the file'):
            patcher.patch_schema(source)
        self.assertEqual(schema.read_text(),original)
        with self.assertRaisesRegex(ValueError,'namespace layout'):
            patcher.compatible_text('unknown layout')
        with self.assertRaisesRegex(ValueError,'number of field_num'):
            patcher.compatible_text('namespace server_schema {\n}\n')

    def test_schema_patch_preserves_numeric_types_and_references(self):
        compiler=shutil.which('c++')
        if compiler is None:
            self.skipTest('A native C++17 compiler is needed for this check')
        patcher=self.load_llama_schema_patcher()
        patcher.EXPECTED_OCCURRENCES=3
        original='''#include <type_traits>
#include <cstdint>
namespace server_schema { template <typename T = int> struct field_num {
    T & val;
    field_num(const char *, T & value) : val(value) {}
}; }
namespace server_schema {
int check() {
    int32_t count=1;
    int64_t large=2;
    float ratio=0.5f;
    auto * a=new field_num("count", count);
    auto * b=new field_num("large", large);
    auto * c=new field_num("ratio", ratio);
    static_assert(std::is_same<decltype(a), field_num<int32_t> *>::value, "int32");
    static_assert(std::is_same<decltype(b), field_num<int64_t> *>::value, "int64");
    static_assert(std::is_same<decltype(c), field_num<float> *>::value, "float");
    a->val=3; b->val=4; c->val=0.75f;
    delete a; delete b; delete c;
    return count==3 && large==4 && ratio==0.75f ? 0 : 1;
}
}
int main() { return server_schema::check(); }
'''
        cpp=self.base/'numeric-types.cpp'
        cpp.write_text(patcher.compatible_text(original))
        binary=self.base/'numeric-types'
        result=subprocess.run([compiler,'-std=c++17',str(cpp),'-o',str(binary)],
                              capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertEqual(subprocess.run([str(binary)]).returncode,0)

if __name__ == '__main__':
    unittest.main(verbosity=2)
