#! /usr/bin/env bash
set -e

l="qwertyuiopasdfghjklzxcvbnm"
n="1234567890"
password=""
length=8
file=""
number=1
save_to_file=0
lock_file="genpass-lock-file"
cmd_check_is_file="test -e"
cmd_check_file="${cmd_check_is_file} ${file}"
cmd_touch="touch"
cmd_check_lock="${cmd_check_is_file} ${lock_file}"
cmd_create_lock="touch ${lock_file}"
cmd_remove_lock="rm -f ${lock_file}"

usage(){
    printf "Password Generator
usage: genpass.sh [OPTIONS]
options:
-h, --help - print this screen
-l, --length [NUMBER] - defines length of password, default is 8
-n, --number [NUMBER] - defines number of passwords to generate
-f, --file [FILE_NAME] - generate password to give file"
}

create_lock(){
    local cmd_create_lock=${1}
    ${cmd_create_lock} 2>/dev/null || {
        printf "Cannot create lock file\n"
        exit 2
    }
}
remove_lock(){
    local cmd_remove_lock=${1}
    ${cmd_remove_lock} 2>/dev/null || {
        printf "Cannot remove lock\n"
        exit 3
    }
}

check(){
    local lcase=0
    local ucase=0
    local num=0
    for (( i=0; i<=${#password}; i++ ))
    do
        local char=${password:$i:1}
        if [[ ${ucase} == 0 ]]; then
            local p='[A-Z]'
            [[ ${char} =~ ${p} ]] && ucase=1
        elif [[ ${lcase} == 0 ]]; then
            local p='[a-z]'
            [[ ${char} =~ ${p} ]] && lcase=1
        elif [[ ${num} == 0 ]]; then
            local p='[0-9]'
            [[ ${char} =~ ${p} ]] && num=1
        fi
    done
    printf '%s' $(( num + lcase + ucase ))
}

save_file(){
    local file="${1}"
    local pw="${2}"
    if [[ "${cmd_check_file}" ]]; then
       printf '%s \n' "${pw}" >> "${file}" 2>/dev/null || {
            printf "Cannot save to file\n"
            remove_lock "${cmd_remove_lock}"
            exit 4
        }
    else
        "${cmd_touch $file}" 2>/dev/null || {
            printf "Cannot create a file\n"
            remove_lock "${cmd_remove_lock}"
            exit 5
        }
        printf '%s \n' "${pw}" > "${file}" 2>/dev/null || {
            printf "Cannot save to file\n"
            remove_lock "${cmd_remove_lock}"
            exit 4
        }
    fi 
}

generate(){
    local check_password=0

    until (( "${check_password}" == 3 ))
    do
        password=""
        for ((i=0; i<length; i++))
        do
            local r=$RANDOM
            if (( r % 10 == 0 ))
            then
                password+="_"
            elif (( r % 3 == 0 ))
            then
                local index=$(( RANDOM % ${#l} ))
                password+=${l:$index:1}
            elif (( r % 2 == 0 ))
            then
                local index=$(( RANDOM % ${#l} ))
                local ch=${l:$index:1}
                password+=${ch^}
            else
                local index=$(( RANDOM % ${#n} ))
                password+=${n:$index:1}
            fi
        done
        check_password=$(check)
    done
    printf '%s' "${password}"
}

if [ -e "${lock_file}" ]; then
    printf "Cannot aquire lock. Check if another instance is running\n"
    exit 1
fi

create_lock "${cmd_create_lock}"

while [ "${1}" != "" ]
do 
    case ${1} in
        -h | --help )
            usage
            exit
            ;;
        -l | --length )
            shift
            length=${1}
            ;;
        -n | --number )
            shift
            number=${1}
            ;;
        -f | --file )
            shift
            file=${1}
            save_to_file=1
            ;;
        * )
            usage
    esac
    shift
done

pass_tab=()
[ "${length}" -eq "${length}" ] 2>/dev/null || {
    printf "Enter correct length value\n"
    remove_lock "${cmd_remove_lock}"
    exit 6
}
[ "${number}" -eq "${number}" ] 2>/dev/null || {
    printf "Enter correct number value\n"
    remove_lock "${cmd_remove_lock}"
    exit 7
}
for (( i=0; i<number; i++ ))
do
    pass_tab+=("$(generate)") 2>/dev/null || {
        printf "Cannot generate a password\n"
        remove_lock "${cmd_remove_lock}"
        exit 8
    }
done
if (( "${save_to_file}" == 1 )); then
    for i in "${pass_tab[@]}"
    do
        save_file "${file}" "${i}" 2>/dev/null || {
            printf "Saving to file failed\n"
            remove_lock "${cmd_remove_lock}"
            exit 9
        }
    done
    save_to_file=0
    printf "Operation complited successfuly\n"
else
 for i in "${pass_tab[@]}"
    do
        printf '%s\n' "${i}"
    done
fi

remove_lock "${cmd_remove_lock}"
