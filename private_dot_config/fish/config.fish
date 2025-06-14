if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Simple alias for HDFView application
alias hdfview='/opt/hdfview/bin/HDFView'

# Complex aliases need to be functions in Fish
function pbcopy
    # Remove trailing newline and copy to clipboard
    # sed -z: treats input as null-terminated (handles multiline)
    # 's/\n$//': removes newline at end
    sed -z 's/\n$//' | xsel --clipboard --input
end

# pbcopyfull function - copies last command AND its output
function pbcopyfull
    # Get the last command from history
    set cmd (history --max=1)
    # Read all input (the command output)
    set output (cat)
    # Format and copy both command and output to clipboard
    printf "Command: %s\n%s\n" "$cmd" "$output" | xsel --clipboard --input
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/heberto/miniconda3/bin/conda
    eval /home/heberto/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/heberto/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/heberto/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/heberto/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <

# Initialize prompt (Starship)
starship init fish | source

# Initialize directory jumper (z command)
zoxide init fish | source

# Load fzf key bindings and functions
# This sets up default fzf bindings like Ctrl+T for file search
fzf --fish | source

# Initialize Atuin for enhanced shell history
# This sets up Ctrl+R for Atuin's native interface
atuin init fish --disable-up-arrow| source

# === CUSTOM KEY BINDINGS ===
# These must come AFTER tool initialization to override defaults

# Ctrl+G: Use fzf's classic history search
# This is the traditional fzf history widget without Atuin
bind \cg fzf-history-widget
if bind -M insert > /dev/null 2>&1
    bind -M insert \cg fzf-history-widget
end

# Ctrl+Alt+R: Enhanced Atuin history with timestamps via fzf
bind \e\cr 'atuin history list --print0 -f "{time} | {command}" | fzf --read0 --delimiter="|" --no-sort | sed "s/^[^|]*| //" | read -l result; and commandline -r $result'
if bind -M insert > /dev/null 2>&1
    bind -M insert \e\cr 'atuin history list --print0 -f "{time} | {command}" | fzf --read0 --delimiter="|" --no-sort | sed "s/^[^|]*| //" | read -l result; and commandline -r $result'
end