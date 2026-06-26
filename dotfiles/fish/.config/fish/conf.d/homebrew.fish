# Put Homebrew on PATH for fish login shells.
#
# setup.sh only eval's `brew shellenv` inside the bash installer process, which
# does not persist. On Apple Silicon /opt/homebrew/bin is NOT on the default
# macOS PATH (/etc/paths), so without this a freshly bootstrapped box opens a
# fish login shell with brew-installed tools (direnv, nvim, uv, gh) missing.
# conf.d/ is sourced before config.fish, so this runs before the direnv hook.
for brew_prefix in /opt/homebrew /usr/local
    if test -x $brew_prefix/bin/brew
        eval ($brew_prefix/bin/brew shellenv)
        break
    end
end
