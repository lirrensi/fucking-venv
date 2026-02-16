#!/bin/sh
# FuckingVenv installer - because typing source .venv/bin/activate is bullshit
#
# Usage:
#   curl -sSL https://.../install.sh | sh
#
# What it does:
#   1. Detects your shell (bash/zsh/fish)
#   2. Appends venv() function to your rcfile
#   3. Sources it RIGHT NOW so it works immediately

set -e

# The venv function - works on bash/zsh
VENV_FUNCTION='
venv() {
    local target="$1"
    local candidates=".venv venv env .env"
    
    if [ -n "$target" ]; then
        # Dot-agnostic: .foo matches foo and vice versa
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
    
    # No argument: try top candidates
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
    
    # Search all folders
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
'

VENV_FUNCTION_FISH='
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
'

MARKER_START="# >>> fuckingvenv >>>"
MARKER_END="# <<< fuckingvenv <<<"

# Detect shell
detect_shell() {
    case "$SHELL" in
        */fish) echo "fish" ;;
        */zsh)  echo "zsh" ;;
        */bash) echo "bash" ;;
        *)      echo "bash" ;;
    esac
}

# Get rcfile for shell
get_rcfile() {
    shell="$1"
    case "$shell" in
        fish) echo "$HOME/.config/fish/config.fish" ;;
        zsh)  echo "$HOME/.zshrc" ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

# Main install
main() {
    shell=$(detect_shell)
    rcfile=$(get_rcfile "$shell")
    
    echo "🐾 Detected shell: $shell"
    echo "🐾 Target rcfile: $rcfile"
    
    # Create directory if needed (fish)
    mkdir -p "$(dirname "$rcfile")" 2>/dev/null || true
    
    # Check if already installed
    if [ -f "$rcfile" ] && grep -q "$MARKER_START" "$rcfile" 2>/dev/null; then
        echo "✨ Already installed! Sourcing..."
        . "$rcfile"
        echo "✨ Done! Try: venv"
        return 0
    fi
    
    # Pick the right function
    case "$shell" in
        fish) func="$VENV_FUNCTION_FISH" ;;
        *)    func="$VENV_FUNCTION" ;;
    esac
    
    # Append to rcfile
    {
        echo ""
        echo "$MARKER_START"
        echo "$func"
        echo "$MARKER_END"
    } >> "$rcfile"
    
    # Source it NOW
    . "$rcfile"
    
    echo ""
    echo "✨ Installed! The 'venv' command is ready."
    echo "   Try it: venv"
    echo ""
    echo "   (Already loaded in this shell - no restart needed!)"
}

main
