# ~/.config/fish/config.fish
# ─────────────────────────────────────────────────────────────────────────────
#  One-file Fish configuration that works on **Apple-silicon macOS** and
#  **Linux**.  Key features:
#    • Adds Home-brew’s /opt/homebrew/{bin,sbin} to PATH for GUI shells
#    • Warns (in red) when optional tools aren’t installed
#    • Initialises Starship, zoxide, fzf, Atuin only if present
#    • Heavy inline comments for future maintenance
# ─────────────────────────────────────────────────────────────────────────────


##############################################################################
# 0.  EXIT EARLY FOR NON-INTERACTIVE SHELLS
##############################################################################
if not status is-interactive
    return
end


##############################################################################
# 1.  OS DETECTION
##############################################################################
set -l OS (uname)            # "Darwin" or "Linux"


##############################################################################
# 2.  HELPER: RED WARNING FOR MISSING TOOLS
##############################################################################
function warn_missing --argument tool
    set_color --bold red
    echo "⚠  '$tool' not found – skipping its initialisation." >&2
    set_color normal
end


##############################################################################
# 3.  DISABLE DEFAULT FISH GREETING
##############################################################################
set -g fish_greeting


##############################################################################
# 4.  ADD HOMEBREW TO PATH (macOS Apple-Silicon ONLY)
#    • GUI apps (WezTerm, iTerm2, Terminal.app) inherit a minimal PATH.
#    • We must prepend /opt/homebrew/bin so Fish can find starship, etc.
##############################################################################
if test $OS = Darwin
    if test -d /opt/homebrew
        eval (/opt/homebrew/bin/brew shellenv)    # Adds bin & sbin, sets vars
    else
        warn_missing Homebrew
    end
end

##############################################################################
# 4b.  ADD ~/.local/bin TO PATH (all OSes)
#    • Many tools (chezmoi, pipx, Rust, etc.) install here.
#    • Ubuntu usually has it already, macOS usually does NOT.
#    • Harmless to add universally — fish_user_paths avoids duplicates.
##############################################################################
if test -d $HOME/.local/bin
    set -Ua fish_user_paths $HOME/.local/bin
end


##############################################################################
# 5.  ABBREVIATIONS & ALIASES
##############################################################################
# Multicd: '..' → cd .. ; '...' → cd ../../ ; etc.
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr --add dotdot --regex '^\.\.+$' --function multicd

# Git shortcuts
abbr gs 'git status'
abbr gb 'git branch'

# HDFView alias (only if binary exists)
if test -x /opt/hdfview/bin/HDFView
    alias hdfview '/opt/hdfview/bin/HDFView'
end


##############################################################################
# 6.  CROSS-PLATFORM CLIPBOARD (`pbcopy` on mac, `xsel`/`xclip` on Linux)
##############################################################################
if test $OS = Linux
    # Complex aliases need to be functions in Fish
    function pbcopy
        # Remove trailing newline and copy to clipboard
        # sed -z: treats input as null-terminated (handles multiline)
        # 's/\n$//': removes newline at end
        sed -z 's/\n$//' | xsel --clipboard --input
    end

    # Copy the last command and its output to the clipboard
    function copyrun
        history save
        set cmd (history --max=1)
        set output (eval $cmd)
        printf "Command: %s\nOutput:\n%s\n" "$cmd" "$output" | pbcopy
    end
end




##############################################################################
# 7.  CONDA INITIALISATION  (Linux-only hard-coded path)
##############################################################################
if test $OS = Linux
    if test -f $HOME/miniconda3/bin/conda
        eval $HOME/miniconda3/bin/conda "shell.fish" "hook" | source
    else if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
        . "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    else
        warn_missing conda
    end
end


##############################################################################
# 8.  OPTIONAL TOOL INITIALISATION  (guarded + warnings)
##############################################################################
# Starship prompt
if type -q starship
    starship init fish | source
else
    warn_missing starship
end

# zoxide directory jumper
if type -q zoxide
    zoxide init fish | source
else
    warn_missing zoxide
end

# fzf bindings & completion
if type -q fzf
    fzf --fish | source
else
    warn_missing fzf
end

# Atuin history
if type -q atuin
    atuin init fish --disable-up-arrow | source
else
    warn_missing atuin
end


##############################################################################
# 9.  CUSTOM KEY-BINDINGS  (must follow tool init)
##############################################################################
# Ctrl-G → classic fzf history
bind \cg fzf-history-widget
if bind -M insert >/dev/null 2>&1
    bind -M insert \cg fzf-history-widget
end

# Ctrl-Alt-R → Atuin history via fzf with timestamps
set -l fzf_atuin 'atuin history list --print0 -f "{time} | {command}" | \
  fzf --read0 --delimiter="|" --no-sort | \
  sed "s/^[^|]*| //" | read -l result; and commandline -r $result'

bind \e\cr $fzf_atuin
if bind -M insert >/dev/null 2>&1
    bind -M insert \e\cr $fzf_atuin
end


##############################################################################
# 10.  MISC ENVIRONMENT
##############################################################################
set -x BAT_THEME 'Solarized (light)'   # Syntax-highlighting theme for bat


##############################################################################
# 11.  NODE VERSION MANAGER (NVM)  ── silent if absent ───────────────────────
#    • Works with either the fish-native plugin (`nvm.fish`) **or**
#      the classic bash/zsh install.
#    • No warning is issued when NVM isn’t present.
##############################################################################
if type -q nvm
    # fish-native plugin: just activate the default Node
    nvm use default --silent >/dev/null 2>&1
else
    # Classic NVM locations
    set -l NVM_DIR $HOME/.nvm
    if test -d /opt/homebrew/opt/nvm
        set NVM_DIR /opt/homebrew/opt/nvm
    else if test -d /usr/local/opt/nvm
        set NVM_DIR /usr/local/opt/nvm
    end
    set -gx NVM_DIR $NVM_DIR

    if test -f $NVM_DIR/nvm.sh
        if type -q bass
            bass source $NVM_DIR/nvm.sh --no-use
        else
            bash -c "source $NVM_DIR/nvm.sh && nvm use default --silent" | source
        end
        # Add current node version's bin directory to PATH
        set -l node_version (bash -c "source $NVM_DIR/nvm.sh && nvm current" 2>/dev/null)
        if test -n "$node_version"; and test -d $NVM_DIR/versions/node/$node_version/bin
            set -gx PATH $NVM_DIR/versions/node/$node_version/bin $PATH
        end
    end
    # If neither plugin nor nvm.sh is found, stay silent.
end

