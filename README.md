# Fucking VENV - single command to forget that venv activation even exists!

Have you fucking tired of doing `sOuRcE .vEnV/bIn/aCtIvAtE` each and every time?!
**I ABSOLUTELY AM.**

## Install

### Unix (bash/zsh/fish)
```bash
eval "$(curl -sSL https://raw.githubusercontent.com/lirrensi/fucking-venv/main/install.sh)"
```

### Windows (PowerShell)
```powershell
iex (iwr https://raw.githubusercontent.com/lirrensi/fucking-venv/main/install.ps1)
```

That's it. One command. Done forever.

## Usage

```bash
venv              # Activates first found venv (.venv, venv, env, .env)
venv myenv        # Activates specific venv (dot-agnostic: matches .myenv or myenv)
```

## How it works

The installer:
1. Detects your shell
2. Appends a `venv()` function to your rcfile
3. Sources it RIGHT NOW

No subshells. No Python subprocesses. Just a shell function that lives in your shell.

## Uninstall

Remove the block between these markers from your rcfile:
```
# >>> fuckingvenv >>>
...
# <<< fuckingvenv <<<
```

## Why not a Python package?

Because the goal is literally just a shell function. Python subprocesses can't modify the parent shell's environment - only a sourced shell function can. The `curl | sh` approach is the honest solution.
