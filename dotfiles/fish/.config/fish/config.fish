if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Guard against direnv not being on PATH yet (fresh box, or fish made the login
# shell before setup.sh installs direnv) — otherwise every shell start errors.
if type -q direnv
    direnv hook fish | source
end
