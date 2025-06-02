if status is-interactive
    # Commands to run in interactive sessions can go here
end


alias hdfview='/opt/hdfview/bin/HDFView'

# Complex aliases need to be functions in Fish
function pbcopy
    sed -z 's/\n$//' | xsel --clipboard --input
end

# pbcopyfull function equivalent
function pbcopyfull
    set cmd (history --max=1)
    set output (cat)
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
# <<< conda initialize <<<

starship init fish | source
zoxide init fish | source

# Load fzf bindings
fzf --fish | source

# Ensure atuin is initialized
atuin init fish | source

# Bind Ctrl+G to fzf history search
bind \cg fzf-history-widget
if bind -M insert > /dev/null 2>&1
    bind -M insert \cg fzf-history-widget
end

# Bind Ctrl+Alt+R to search Atuin history with fzf
bind \e\cr 'atuin search --cmd-only | fzf --no-sort --exact | read -l result; and commandline -r $result'
if bind -M insert > /dev/null 2>&1
    bind -M insert \e\cr 'atuin search --cmd-only | fzf --no-sort --exact | read -l result; and commandline -r $result'
end
