
This `dev` repository contains the scripts and setup files used to provision
the programming languages, models, and command-line tools required by Zorks
Illustrated. Tools are installed beneath this checkout rather than globally,
so the setup does not require administrator privileges.

From the top level of this repository:

```bash
./GET-DEV-TOOLS-ALL.sh
```

The parent Zorks Illustrated repository activates the installed tools by
sourcing its top-level `SETUP.bash`, which in turn sources `dev/SETUP.bash`.

## Local command-interpreter model

`cli-tools/GET-LLAMA-CPP.sh` downloads a pinned, official CPU build of
`llama.cpp` for supported Windows, Linux, and macOS systems. The executable is
installed locally as `cli-tools/llama-cpp/`.

`cli-tools/GET-LLAMA-CPP-MODEL.sh` downloads the pinned, non-thinking Qwen2.5
1.5B Instruct Q4_K_M GGUF model used to translate natural-language requests
into original Zork parser commands. The 1.12 GB model is saved beneath
`cli-tools/llama-cpp-models/` and verified against its published SHA-256 digest.
The smaller model is deliberately selected for low-latency CPU inference while
leaving the GPU available for illustration generation.

Both generated directories and their download archives are ignored by Git.
The parent repository supplies `RUN-LLAMA-CPP-SERVER.sh`, which starts the
locally installed CPU server. Its `npm run dev` command can start or reuse that
server automatically when command interpretation is enabled.
