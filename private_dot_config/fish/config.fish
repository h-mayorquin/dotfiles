if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

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

zoxide init fish | source
