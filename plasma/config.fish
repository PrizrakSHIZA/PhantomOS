if status is-interactive
    starship init fish | source
    abbr --add ll 'ls -alF'
    abbr --add c 'clear'
    abbr --add y 'yazi'
end
