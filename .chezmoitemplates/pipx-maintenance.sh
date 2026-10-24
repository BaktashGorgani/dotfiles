# Shared by the install and update templates. Run only after OS/Homebrew
# packages are ready; never pick Homebrew Python accidentally on Linux.
function maintain_pipx() {
    local mode="$1"
    shift
    local python pipx_bin prefix version venvs bins package venv
    case "$(uname -s)" in
        Linux)
            python=/usr/bin/python3
            pipx_bin=/usr/bin/pipx
            ;;
        Darwin)
            prefix="$(brew --prefix python)" || return 1
            python="$prefix/bin/python3"
            prefix="$(brew --prefix pipx)" || return 1
            pipx_bin="$prefix/bin/pipx"
            ;;
        *)
            printf 'Unsupported OS for pipx maintenance: %s\n' "$(uname -s)" >&2
            return 1
            ;;
    esac
    if [[ ! -x "$python" || ! -x "$pipx_bin" ]]; then
        printf 'pipx maintenance requires %s and %s\n' "$python" "$pipx_bin" >&2
        return 1
    fi
    # Also applies when pipx recreates its own shared pip environment.
    export PIPX_DEFAULT_PYTHON="$python"
    version="$("$python" -c 'import sys; print("%d.%d" % sys.version_info[:2])')" || return 1
    venvs="$("$pipx_bin" environment --value PIPX_LOCAL_VENVS)" || return 1
    bins="$("$pipx_bin" environment --value PIPX_BIN_DIR)" || return 1
    if [[ -z "$venvs" || -z "$bins" ]]; then
        printf 'pipx returned empty environment paths\n' >&2
        return 1
    fi
    for package in "$@"; do
        venv="$venvs/$package"
        if [[ ! -d "$venv" ]]; then
            printf 'Installing pipx package %s...\n' "$package"
            "$pipx_bin" install --python "$python" "$package" || return 1
        elif ! pipx_package_healthy "$venv" "$bins/$package" "$version"; then
            printf 'Repairing pipx package %s with %s...\n' "$package" "$python"
            "$pipx_bin" reinstall --python "$python" "$package" || return 1
        fi
        if [[ "$mode" == update ]]; then
            "$pipx_bin" upgrade --include-injected "$package" || return 1
        fi
        if ! pipx_package_healthy "$venv" "$bins/$package" "$version"; then
            printf 'pipx package %s failed verification\n' "$package" >&2
            return 1
        fi
    done
}

function pipx_package_healthy() {
    local venv="$1" launcher="$2" expected="$3" actual
    actual="$("$venv/bin/python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)" || return 1
    [[ "$actual" == "$expected" ]] || return 1
    # Declared packages must expose a same-named CLI supporting --version.
    # Run the exported launcher too: an executable file can have a dead shebang.
    "$launcher" --version >/dev/null 2>&1
}
