"""FuckingVenv - for pipx users who want the long way around."""

import os
import sys
from pathlib import Path

# Fix Windows console encoding for emojis
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")


TOP_CANDIDATES = [".venv", "venv", "env", ".env"]

MARKER_START = "# >>> fuckingvenv >>>"
MARKER_END = "# <<< fuckingvenv <<<"

VENV_FUNCTION = """
venv() {
    local target="$1"
    local candidates=".venv venv env .env"
    
    if [ -n "$target" ]; then
        local clean_target="${target#.}"
        for d in */ .*/; do
            [ -d "$d" ] || continue
            local name="${d%/}"
            local clean_name="${name#.}"
            if [ "$clean_name" = "$clean_target" ]; then
                if [ -f "$name/bin/activate" ]; then
                    echo "✨ Activating: $name" >&2
                    . "$PWD/$name/bin/activate"
                    return 0
                elif [ -f "$name/Scripts/activate" ]; then
                    echo "✨ Activating: $name" >&2
                    . "$PWD/$name/Scripts/activate"
                    return 0
                fi
            fi
        done
        echo "💔 No venv found: $target" >&2
        return 1
    fi
    
    for c in $candidates; do
        if [ -f "$PWD/$c/bin/activate" ]; then
            echo "✨ Activating: $c" >&2
            . "$PWD/$c/bin/activate"
            return 0
        elif [ -f "$PWD/$c/Scripts/activate" ]; then
            echo "✨ Activating: $c" >&2
            . "$PWD/$c/Scripts/activate"
            return 0
        fi
    done
    
    for d in */ .*/; do
        [ -d "$d" ] || continue
        local name="${d%/}"
        if [ -f "$name/bin/activate" ]; then
            echo "✨ Activating: $name" >&2
            . "$name/bin/activate"
            return 0
        elif [ -f "$name/Scripts/activate" ]; then
            echo "✨ Activating: $name" >&2
            . "$name/Scripts/activate"
            return 0
        fi
    done
    
    echo "💔 No venv found (tried: $candidates)" >&2
    return 1
}
"""

VENV_FUNCTION_FISH = """
function venv --argument target
    set candidates .venv venv env .env
    
    if test -n "$target"
        set clean_target (string replace -r "^\\." "" -- $target)
        for d in */ .*/
            test -d $d; or continue
            set name (string replace -r "/$" "" -- $d)
            set clean_name (string replace -r "^\\." "" -- $name)
            if test "$clean_name" = "$clean_target"
                if test -f "$name/bin/activate.fish"
                    echo "✨ Activating: $name" >&2
                    source "$name/bin/activate.fish"
                    return 0
                else if test -f "$name/bin/activate"
                    echo "✨ Activating: $name" >&2
                    source "$name/bin/activate"
                    return 0
                end
            end
        end
        echo "💔 No venv found: $target" >&2
        return 1
    end
    
    for c in $candidates
        if test -f "$PWD/$c/bin/activate.fish"
            echo "✨ Activating: $c" >&2
            source "$PWD/$c/bin/activate.fish"
            return 0
        else if test -f "$PWD/$c/bin/activate"
            echo "✨ Activating: $c" >&2
            source "$PWD/$c/bin/activate"
            return 0
        end
    end
    
    echo "💔 No venv found (tried: $candidates)" >&2
    return 1
end
"""

VENV_FUNCTION_PWSH = """
function venv {
    param([string]$Name)

    $candidates = @(".venv", "venv", "env", ".env")

    if ($Name) {
        $cleanTarget = $Name.TrimStart(".")
        Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $cleanName = $_.Name.TrimStart(".")
            if ($cleanName -eq $cleanTarget) {
                $activate = Join-Path $_.FullName "Scripts\\Activate.ps1"
                if (Test-Path $activate) {
                    Write-Host "✨ Activating: $($_.Name)" -ForegroundColor Green
                    . $activate
                    return
                }
            }
        }
        Write-Host "💔 No venv found: $Name" -ForegroundColor Red
        return
    }

    foreach ($c in $candidates) {
        $activate = Join-Path $PWD "$c\\Scripts\\Activate.ps1"
        if (Test-Path $activate) {
            Write-Host "✨ Activating: $c" -ForegroundColor Green
            . $activate
            return
        }
    }

    Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $activate = Join-Path $_.FullName "Scripts\\Activate.ps1"
        if (Test-Path $activate) {
            Write-Host "✨ Activating: $($_.Name)" -ForegroundColor Green
            . $activate
            return
        }
    }

    Write-Host "💔 No venv found here" -ForegroundColor Red
}
"""

# Batch file for cmd.exe - uses call to run in same shell context
VENV_BAT = r"""@echo off
setlocal enabledelayedexpansion

set "TARGET=%~1"
set "CANDIDATES=.venv venv env .env"

if defined TARGET (
    rem Dot-agnostic matching
    set "CLEAN_TARGET=!TARGET:.=!"
    for /d %%d in (*) do (
        set "NAME=%%d"
        set "CLEAN_NAME=!NAME:.=!"
        if "!CLEAN_NAME!"=="!CLEAN_TARGET!" (
            if exist "%%d\Scripts\activate.bat" (
                echo ✨ Activating: %%d
                endlocal
                call "%%d\Scripts\activate.bat"
                exit /b 0
            )
        )
    )
    echo 💔 No venv found: %TARGET%
    exit /b 1
)

rem No argument: try candidates
for %%c in (%CANDIDATES%) do (
    if exist "%%c\Scripts\activate.bat" (
        echo ✨ Activating: %%c
        endlocal
        call "%%c\Scripts\activate.bat"
        exit /b 0
    )
)

rem Search all folders
for /d %%d in (*) do (
    if exist "%%d\Scripts\activate.bat" (
        echo ✨ Activating: %%d
        endlocal
        call "%%d\Scripts\activate.bat"
        exit /b 0
    )
)

echo 💔 No venv found here
exit /b 1
"""


def detect_shell() -> str:
    """Detect the current shell."""
    if sys.platform == "win32":
        # Check for PowerShell first
        if os.environ.get("PSModulePath"):
            return "powershell"
        # Check for cmd.exe
        if os.environ.get("COMSPEC", "").lower().endswith("cmd.exe"):
            return "cmd"
    shell = os.environ.get("SHELL", "")
    if "fish" in shell:
        return "fish"
    if "zsh" in shell:
        return "zsh"
    return "bash"


def get_rcfile(shell: str) -> Path:
    """Get the rc file path for the shell."""
    home = Path.home()
    if shell == "powershell":
        profile = os.environ.get("PROFILE", "")
        if profile:
            return Path(profile)
        return home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1"
    if shell == "fish":
        return home / ".config" / "fish" / "config.fish"
    if shell == "zsh":
        return home / ".zshrc"
    return home / ".bashrc"


def get_bin_dir() -> Path:
    """Get user's local bin directory for batch files."""
    home = Path.home()
    if sys.platform == "win32":
        # Use AppData\Local\bin on Windows
        bin_dir = home / "AppData" / "Local" / "bin"
    else:
        bin_dir = home / ".local" / "bin"
    return bin_dir


def install_unix(shell: str) -> int:
    """Install for Unix shells (bash/zsh/fish)."""
    rcfile = get_rcfile(shell)
    rcfile.parent.mkdir(parents=True, exist_ok=True)

    if rcfile.exists() and MARKER_START in rcfile.read_text(encoding="utf-8"):
        print(f"✨ Already installed in {rcfile}")
        print(f"   Run: source {rcfile}")
        return 0

    func = VENV_FUNCTION_FISH if shell == "fish" else VENV_FUNCTION
    block = f"\n{MARKER_START}\n{func}\n{MARKER_END}\n"

    with open(rcfile, "a", encoding="utf-8") as f:
        f.write(block)

    print(f"✨ Installed to {rcfile}")
    print(f"   Run: source {rcfile}")
    return 0


def uninstall_unix(shell: str) -> int:
    """Uninstall from Unix shells."""
    rcfile = get_rcfile(shell)
    if not rcfile.exists():
        print("💔 No rcfile found")
        return 1
    content = rcfile.read_text(encoding="utf-8")
    if MARKER_START not in content:
        print("💔 Not installed")
        return 1
    lines = content.split("\n")
    new_lines = []
    skip = False
    for line in lines:
        if MARKER_START in line:
            skip = True
        elif MARKER_END in line:
            skip = False
        elif not skip:
            new_lines.append(line)
    rcfile.write_text("\n".join(new_lines), encoding="utf-8")
    print(f"✨ Removed from {rcfile}")
    return 0


def install_windows() -> int:
    """Install for Windows - both PowerShell and cmd.exe."""
    success = True

    # Install PowerShell function
    ps_profile = get_rcfile("powershell")
    ps_profile.parent.mkdir(parents=True, exist_ok=True)

    if ps_profile.exists() and MARKER_START in ps_profile.read_text(encoding="utf-8"):
        print(f"✨ PowerShell: already installed")
    else:
        block = f"\n{MARKER_START}\n{VENV_FUNCTION_PWSH}\n{MARKER_END}\n"
        with open(ps_profile, "a", encoding="utf-8") as f:
            f.write(block)
        print(f"✨ PowerShell: installed to {ps_profile}")

    # Install cmd.exe batch file
    bin_dir = get_bin_dir()
    bin_dir.mkdir(parents=True, exist_ok=True)
    bat_file = bin_dir / "venv.bat"

    bat_file.write_text(VENV_BAT, encoding="utf-8")
    print(f"✨ cmd.exe: installed to {bat_file}")

    # Check if bin_dir is in PATH
    path_env = os.environ.get("PATH", "")
    if str(bin_dir) not in path_env:
        print(f"\n⚠️  Add {bin_dir} to your PATH:")
        print(
            f"   PowerShell: [Environment]::SetEnvironmentVariable('PATH', $env:PATH + ';{bin_dir}', 'User')"
        )
        print(f'   cmd.exe: setx PATH "%PATH%;{bin_dir}"')

    print(f"\n✨ Done! Restart your shell or:")
    print(f"   PowerShell: . {ps_profile}")
    print(f"   cmd.exe: open new terminal")

    return 0 if success else 1


def uninstall_windows() -> int:
    """Uninstall from Windows."""
    # Remove PowerShell function
    ps_profile = get_rcfile("powershell")
    if ps_profile.exists():
        content = ps_profile.read_text(encoding="utf-8")
        if MARKER_START in content:
            lines = content.split("\n")
            new_lines = []
            skip = False
            for line in lines:
                if MARKER_START in line:
                    skip = True
                elif MARKER_END in line:
                    skip = False
                elif not skip:
                    new_lines.append(line)
            ps_profile.write_text("\n".join(new_lines), encoding="utf-8")
            print(f"✨ PowerShell: removed from {ps_profile}")

    # Remove batch file
    bat_file = get_bin_dir() / "venv.bat"
    if bat_file.exists():
        bat_file.unlink()
        print(f"✨ cmd.exe: removed {bat_file}")

    print("✨ Uninstalled!")
    return 0


def main():
    """Install venv function."""
    import argparse

    parser = argparse.ArgumentParser(description="Install venv shell function")
    parser.add_argument(
        "--uninstall", "-u", action="store_true", help="Remove from rcfile"
    )
    args = parser.parse_args()

    if sys.platform == "win32":
        if args.uninstall:
            return uninstall_windows()
        return install_windows()

    # Unix
    shell = detect_shell()
    if args.uninstall:
        return uninstall_unix(shell)
    return install_unix(shell)


if __name__ == "__main__":
    sys.exit(main())
