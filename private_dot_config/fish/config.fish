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

starship init fish | source
zoxide init fish | source

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

