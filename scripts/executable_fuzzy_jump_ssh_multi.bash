#!/bin/bash
# eh I made some changes to this script and broke it. It still works but sometimes
# misbehaves. Not even going to bother to fix it, this is getting a rewrite in Go
# soon. 2 programs, 1 for ssh management and 1 for tmux management.


jump_ssh () {
    local connectName
    if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
        echo "Usage: olympus_con <Jump Server> <Router FQDN or IP OR Nickname if available> <New Nickname (optional)>"
        return 1
    fi
    local jumpServer="$1"
    local ipOrDns="$2"
    if [[ $jumpServer =~ "Direct" ]]; then
        if [[ ! -f "$HOME/.connections/$ipOrDns.passwd.gpg" ]]; then
            echo "Password file for $ipOrDns not found"
            return 1
        fi
    else
        if ! grep -q "$jumpServer" "$HOME/.connections/jumpservers"; then
            echo "Jump server not found in $HOME/.connections/jumpservers"
            return 1
        fi
        if [[ ! -f $HOME/.connections/$jumpServer.passwd.gpg ]]; then
            echo "Password file for $jumpServer not found"
            return 1
        fi
        if [[ ! -f "$HOME/.connections/tacacs.passwd.gpg" ]]; then
            echo "Password file for tacacs not found"
            return 1
        fi
        echo "Jumpserver set to $jumpServer"
    fi
    if [[ -z "$3" ]]; then
        local name="$ipOrDns"
    else
        local name="$3"
    fi
    if [[ ! -f "$HOME/.connections/$jumpServer" ]]; then
        mkdir -p "$HOME/.connections"
        touch "$HOME/.connections/$jumpServer"
    fi
    if grep -q "^$name\\s$ipOrDns$" "$HOME/.connections/$jumpServer"; then
        echo "Connection entry exists!"
        connectName=$ipOrDns
    elif grep -q "$name\\s" "$HOME/.connections/$jumpServer"; then

        # TODO: use mapfile for array to avoid dirty, stinkin shell globbin...
        # lines 49, 116, 201, 202, 205, 217, 223, and 276

        local entryArray=($(grep -e "^$name\\s" -e "\\s$name$" "$HOME/.connections/$jumpServer"))
        local nameInFile=${entryArray[0]}
        local ipInFile=${entryArray[1]}
        if [[ "$nameInFile" == "$ipInFile" ]]; then
            connectName=$nameInFile
        else
            connectName=$ipInFile
        fi
    else
        local ipRegex="^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$"
        if [[ $ipOrDns =~ $ipRegex ]]; then
            if grep -q "\\s$ipOrDns$" "$HOME/.connections/$jumpServer"; then
                local nameInFile
                echo "Connection entry exists!"
                nameInFile=$(grep -oP "^.*(?= $ipOrDns$)" "$HOME/.connections/$jumpServer")
                echo "$ipOrDns is already associated with the name '$nameInFile'. Do you want to overwrite it with '$name'?"
                select ync in "Yes" "No" "Cancel"; do
                    case $ync in
                        Yes ) sed -i "s/$nameInFile $ipOrDns/$name $ipOrDns/" "$HOME/.connections/$jumpServer"; echo "Connection entry name changed"; break;;
                        No ) echo "Connection entry left alone"; break;;
                        Cancel ) return 1;;
                        * ) echo "Please answer 1 for Yes, 2 for No, or 3 for Cancel";;
                    esac
                done
            else
                echo "Connection entry does not exist."
                if [[ "$name" == "$ipOrDns" ]]; then
                    echo "Adding $name to connection list"
                else
                    echo "Adding $name($ipOrDns) to connection list"
                fi
                echo "$name $ipOrDns" >> "$HOME/.connections/$jumpServer"
            fi
            connectName=$ipOrDns
        else
            local cvSuffix=".cv.net"
            local stripCvSuffix=${name%"$cvSuffix"}
            local cvName="$stripCvSuffix$cvSuffix"
            local alticeSuffix=".alticeusa.net"
            local stripAlticeSuffix=${name%"$alticeSuffix"}
            local alticeName="$stripAlticeSuffix$alticeSuffix"
            if grep -q "$cvName\\s" "$HOME/.connections/$jumpServer"; then
                echo "Connection entry exists!"
                connectName=$cvName
            elif grep -q "$alticeName\\s" "$HOME/.connections/$jumpServer"; then
                echo "Connection entry exists!"
                connectName=$alticeName
            else
                echo "Connection entry does not exist."
                if nslookup "$cvName" > /dev/null; then
                    echo "DNS entry found for $cvName"
                    echo "Adding $cvName to connection list"
                    echo "$cvName $cvName" >> "$HOME/.connections/$jumpServer"
                    connectName=$cvName
                elif nslookup "$alticeName" > /dev/null; then
                    echo "DNS entry found for $alticeName"
                    echo "Adding $alticeName to connection list"
                    echo "$alticeName $alticeName" >> "$HOME/.connections/$jumpServer"
                    connectName=$alticeName
                else
                    echo "Neither $cvName or $alticeName are valid DNS names"
                    return 1
                fi
            fi
        fi
    fi

    local entryArray=($(grep -e "^$connectName\\s" -e "\\s$connectName$" "$HOME/.connections/$jumpServer"))
    local connectName=${entryArray[0]}
    local connectIp=${entryArray[1]}
    local windowName=$connectName
    local cvSuffix=".cv.net"
    local stripCvSuffix=${connectName%"$cvSuffix"}
    local alticeSuffix=".alticeusa.net"
    local connectName=${stripCvSuffix%"$alticeSuffix"}
    if [[ $jumpServer =~ "Direct" ]]; then
        echo "Connecting directly to $connectName"
    elif [[ "$connectName" == "$connectIp" ]]; then
        echo "Connecting to $connectName through $jumpServer"
    else
        echo "Connecting to $connectName($connectIp) through $jumpServer"
        connectName=$connectIp
    fi


    # TODO: this needs a rewrite now that the jump connection is happening through
    # ssh config file and letting the connection through the JS use a RSA key.
    # Not to mention this was insecure as heck because the password was visible in
    # the process list...there are better ways to use sshpass like either
    # with SSHPASS env var or with a random file descriptor. This was a good start...

    local cmd

    if [[ "$jumpServer" =~ "Direct" ]]; then
        local pass
        pass=$(gpg -d -q "$HOME/.connections/$connectName.passwd.gpg")
        if [[ -n "$TMUX" ]]; then
            cmd="tmux new-window -n $windowName 'sshpass -p $pass ssh -t bgorgani@$connectName;while true;do sleep 1;done'"
            if ! "$cmd"; then
                tmux new-window -n "$windowName" "ssh -t bgorgani@$connectName;while true;do sleep 1;done"
            fi
        else
            cmd="sshpass -p $pass ssh -t bgorgani@$connectName"
            if ! "$cmd"; then
                ssh -t bgorgani@"$connectName"
            fi
        fi
    else
        local jumpPass
        local tacacsPass
        jumpPass=$(gpg -d -q "$HOME/.connections/$jumpServer.passwd.gpg")
        tacacsPass=$(gpg -d -q "$HOME/.connections/tacacs.passwd.gpg")
        if [[ -n "$TMUX" ]]; then
            cmd="tmux new-window -n $windowName 'sshpass -p $jumpPass ssh -t bgorgani@$jumpServer \"sshpass -p $tacacsPass ssh bgorgani@$connectName\";while true;do sleep 1;done'"
            if ! "$cmd"; then
                tmux new-window -n "$windowName" "sshpass -p $jumpPass ssh -t bgorgani@$jumpServer \"ssh bgorgani@$connectName\";while true;do sleep 1;done"
            fi
        else
            cmd="sshpass -p $jumpPass ssh -t bgorgani@$jumpServer \"sshpass -p $tacacsPass ssh bgorgani@$connectName\""
            if ! "$cmd"; then
                sshpass -p "$jumpPass" ssh -t bgorgani@"$jumpServer" "ssh bgorgani@$connectName"
            fi
        fi
    fi
}

sanitize_and_connect () {
    local jumpServer="$1"
    local selections=("$@")
    local sanitizedSelections=()
    for i in "${!selections[@]}"; do
        if [[ "${selections[$i]}" != "$jumpServer" ]]; then
            new_selections+=("${selections[$i]}")
        fi
    done
    selections=("${new_selections[@]}")

    # TODO: should probably expicitly concatenate here but I need to make sure it
    # doesn't break...

    if [[ -z "${selections[@]}" ]]; then
        echo "No entry selected"
        return 1
    fi
    if [[ "${#selections[@]}" -eq 1 ]]; then
        if [[ "${selections[0]}" =~ "'" ]]; then
            selections[0]=${selections[0]:1}
        fi
        sanitizedSelections=("${selections[0]}:${selections[0]}")
    elif [[ "${#selections[@]}" -eq 2 ]]; then
        if grep -q "^${selections[0]}\\s" "$HOME/.connections/$jumpServer" &&
            grep -q "^${selections[1]}\\s" "$HOME/.connections/$jumpServer"; then
            local entryArray1=($(grep "^${selections[0]}\\s" "$HOME/.connections/$jumpServer"))
            local entryArray2=($(grep "^${selections[1]}\\s" "$HOME/.connections/$jumpServer"))
            sanitizedSelections=("${entryArray1[0]}:${entryArray1[1]}" "${entryArray2[0]}:${entryArray2[1]}")
        elif grep -q "\\s${selections[1]}$" "$HOME/.connections/$jumpServer"; then
            local entryArray=($(grep "\\s${selections[1]}$" "$HOME/.connections/$jumpServer"))
            sanitizedSelections=("${entryArray[0]}:${entryArray[1]}")
        else
            if [[ "${selections[0]}" =~ "'" ]]; then
                selections[0]=${selections[0]:1}
            fi
            sanitizedSelections=("${selections[0]}:${selections[1]}")
        fi
    elif [[ "${#selections[@]}" -gt 2 ]]; then
        for i in "${selections[@]}"; do
            if [[ -n "$i" ]]; then
                if grep -q "$i" "$HOME/.connections/$jumpServer"; then
                    local entryArray=($(grep "$i" "$HOME/.connections/$jumpServer"))
                    sanitizedSelections+=("${entryArray[0]}:${entryArray[1]}")
                fi
            fi
        done
    fi
    local uniqSelection=($(printf "%s\n" "${sanitizedSelections[@]}" | uniq))
    for entry in "${uniqSelection[@]}"; do
        local name
        local ip
        IFS=':' read -r name ip <<< "$entry"
        jump_ssh "$jumpServer" "$ip" "$name"
    done
}

create_jumpservers () {
    while read -r jumpServer; do
        if [[ ! -f "$HOME/.connections/$jumpServer" ]]; then
            touch "$HOME/.connections/$jumpServer"
        fi
    done < "$HOME/.connections/jumpservers"
}

connect_header="Select an entry (or Tab to select multiple) and hit enter to connect

To create a new entry, type the FQDN or IP address and press enter to connect

Alternatively, when creating a new entry,
you can enter a Nickname followed by an IP

(Note: You cannot create a new entry AND connect
to multiple entries at the same time)"

fjs () {
    local jumpServer
    local selection

    create_jumpservers

    jumpServer=$(
        (cat "$HOME/.connections/jumpservers"; echo "Direct") |
        fzf --prompt="Choose a jump server: " --preview="cat $HOME/.connections/{}"
    )
    if [[ -z "$jumpServer" ]]; then
        echo "No jump server selected"
        return 1
    fi
    selection=$(
        printf "Add/Connect\nChange entry\nDelete entry" |
        fzf --prompt="Choose an action: " \
            --preview="cat $HOME/.connections/$jumpServer" \
    )
    if [[ -z "$selection" ]]; then
        echo "No action selected"
        return 1
    fi
    case $selection in
        "Add/Connect" )
            local selectionArray=(
                $(
                    awk '{ if ($1 != $2) print $1, $2; else print $1 }' "$HOME/.connections/$jumpServer" |
                    fzf --style 'full' -i -m --ansi --print-query --prompt="Connect to: " \
                    --preview="echo {} | awk '{print \$1}' | xargs dig " \
                    --header="$connect_header"
                )
            )
            sanitize_and_connect "$jumpServer" "${selectionArray[@]}"
            ;;
        "Change entry" )
            if [[ -n "$TMUX" ]]; then
                tmux display-popup "$HOME/.connections/scripts/fjs_change_entry.bash" "$jumpServer"
            else
                "$HOME/.connections/scripts/fjs_change_entry.bash" "$jumpServer"
            fi
            ;;
        "Delete entry" )
            if [[ -n "$TMUX" ]]; then
                tmux display-popup "$HOME/.connections/scripts/fjs_delete_entry.bash" "$jumpServer"
            else
                "$HOME/.connections/scripts/fjs_delete_entry.bash" "$jumpServer"
            fi
            ;;
    esac
}

GPG_TTY=$(tty)
export GPG_TTY

if [[ -n "$TMUX" ]]; then
    fjs
    if ! fjs; then
        read -n 1 -s -r -p "Press any key to continue"
    fi
else
    fjs
fi
