#!/usr/bin/env sh

DBInstanceId=
Username=
Password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' </dev/urandom|head -c 20)
DBNames=
dryrun=0
Archery="archery_test"

function usage() {
    cat << HEREDOC
    
    Usage: $(basename $0) --DBInstanceId string --DBNames string --Username string [--Archery string] [--Password string]
    
    required arguments:
        -d, --DBNames       dbnames to be created. splited with space
        -i, --DBInstanceId  instanceId which the databases belong to
        -u, --Username      username to be granted privilege.

    optional arguments:
        -h, --help          show this help message and exit
        -a, --Archery       username of archery platform for sql review.default archery_test
        -p, --Password      default a random string of lenth 20
        --dryrun            debug mode
HEREDOC
}

function invalid() {
    echo "ERROR: Unrecognized argument $1 ">&2
    exit 1
}

function require() {
    echo "ERROR: $1 required" >&2
    exit 1
}
function ParseArguments() {
    while [ $# -gt 0 ];do
        case "$1" in
            -h|--help)          usage; exit 0;;
            -d|--DBNames)       shift; DBNames="$1"; shift;;
            -i|--DBInstanceId)  shift; DBInstanceId="$1"; shift;;
            -u|--Username)      shift; Username="$1"; shift;;
            -a|--Archery)       shift; Archery="$1"; shift;;
            -p|--Password)      shift; Password="$1"; shift;;
            --dryrun)           dryrun=1; shift ;;
            --)                 shift; break ;;
            *)                  invalid "$1";;
        esac    
    done
}
function CreateDatabases() {
    echo "CreateDatabases '${DBNames// /,}'"
    for DBName in $DBNames;do
        aliyun rds CreateDatabase \
            --CharacterSetName 'utf8' \
            --DBInstanceId  "$DBInstanceId" \
            --DBName "$DBName"   \
            &>/dev/null   \
            $1
        code=$?
        if [ ! $code -eq 0 ]; then
	        echo "CreateDatabases ERROR: $code" >&2
            exit 1
        fi
   done
}

function CreateUser() {
    echo "CreateUser $Username"
    aliyun rds CreateAccount \
        --AccountName "$Username" \
        --AccountPassword "$Password" \
        --DBInstanceId   "$DBInstanceId" \
        --AccountType   "Normal"  \
        &>/dev/null \
        $1
    code=$?
    if [ $code -eq 0 ];then
        echo "Username: $Username\t Password: $Password"
    else
        echo "CreateUser ERROR: $code" >&2
    fi
}

function GrantPrivileges() {
    username=$1
    echo "GrantPrivileges: grant ReadWrite Privilege on '${DBNames// /,}' to $username."
    for DBName in $DBNames; do
        aliyun rds GrantAccountPrivilege \
            --AccountName "$username"  \
            --AccountPrivilege "ReadWrite" \
            --DBInstanceId  "$InstanceID" \
            --DBName "$DBName"   \
            &>/dev/null \
            $2
        code=$?
        if [ ! $code -eq 0 ];then 
            echo "GrantPrivilege ERROR: $code" >&2
            exit 1
        fi
    done
}

function Run() {
    CreateDatabases 
    CreateUser 
    GrantPrivileges "$Username" 
    GrantPrivileges "$Archery" 
}

function Dryrun() {
    CreateDatabases --dryrun
    CreateUser --dryrun
    GrantPrivileges "$Username" --dryrun
    GrantPrivileges "$Archery" --dryrun
}


ParseArguments "$@"
if [ "x$DBInstanceId" =  "x" ];then
    require "DBInstanceId"
fi

if [ "x$DBNames" = "x" ];then
    require "DBNames"
fi

if [ "x$Username" = "x" ]; then
    require "Username"
fi

if [ $dryrun -eq 1 ];then
    Dryrun
else
    Run
fi

