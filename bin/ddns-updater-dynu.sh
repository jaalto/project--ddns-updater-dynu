#! /bin/sh
#
# Requires: curl(1)

AUTHOR="Jari Aalto <jari.aalto@cante.net>"
VERSION="2021.0129.1903"
LICENSE="GPL-2+"
HOMEPAGE="https://github.com/jaalto/project--ddns-updater-dynu"

PROGRAM=ddns-updater

# mktemp(1) would be an external program
TMPDIR=${TMPDIR:-/tmp}
TMPBASE=$TMPDIR/$PROGRAM.$$

PREFIX="dynu: "
GETIP=ifconfig.co
TMPDIR=${TMPDIR:-/tmp}
TTL=120

CONFDIR=
DOMAIN=
ID=
APIKEY=

# -----------------------------------------------------------------------
# HELP
# -----------------------------------------------------------------------

Help ()
{
    echo "Synopis: $0 [options]
DESCRIPTION
    Update DOMAIN and IP at dynu.net Dynamic DNS service.

OPTIONS
    -a, --apikey APIKEY
        The API-Key from
        https://www.dynu.com/ControlPanel/APICredentials

    -c, --confdir CONFDIR
        Location of *.conf files. If given, no other option than
        --test and --verbose are used. Typical locations are
        ~/.config/ddns-updater-dynu and /etc/ddns-updater-dynu

    -d, --domain DOMAIN
        Required. Domain like example.dynuddns.net in your dynu.com
        account.

    -g, --getip HOST
        Optional. Host to get ip. Must return single IP address and
        nothing else. Default: $GETIP

    -i, --id HOSTID
        Required. The ID of the dynamic host. See --query.

    -I, --ip IP
        Optional. The IP address. If not given, call network.
        See option --getip.

    -Q, --query
        Query hostlist. From this you can find out the HOSTID.
        Display and exit.

    -t, --test
        Test. Run no commands.

    -T, --ttl SECONDS
        Time to live in seconds. Default: $TTL

    -v, --verbose
        Display verbose messages.

    -V, --version
        Display version information and exit.

    -h, --help
        Display short help and exit.

EXAMPLES
    ddns-updater-dynu --apikey KEY --query

    ddns-updater-dynu --confdir ~/.config/ddns-updater-dynu --verbose --test

FILES
    The configuration files are read from directory --confdir CONF
    The file must be *.conf and be in standards POSIX shell format.

    Each file must define following variables:

        # If empty or does not exist, the configuration is not used
        ENABLE=yes

        # Option for --apikey APIKEY
        APIKEY=

        # Option for --id ID
        ID=

        # Option for --domain DOMAIN
        DOMAIN=

BUGS
    This is a POSIX shell script. Options must be kept separate. It is
    not possible to combine options '-v -t' into '-vt'.

REQUIRES
    curl(1)
    json_pp(1)    Optional. Used if available from Perl to format --query"
}

# -----------------------------------------------------------------------
# HELP
# -----------------------------------------------------------------------

Atexit ()
{
    rm -f "$TMPBASE"*   # Clean up temporary files
}

Version()
{
    echo "$VERSION $LICENSE $AUTHOR $HOMEPAGE"
}

Warn ()
{
    echo "$PREFIX$*" >&2
}

Die ()
{
    Warn "$*"
    exit 1
}

DieIfEmpty ()
{
    if [ ! "$1" ]; then
        Die "$*"
    fi
}

WarnIfEmpty ()
{
    if [ ! "$1" ]; then
        Warn "$*"
        return 1
    fi
}

Verbose ()
{
    [ "$verbose" ] && echo "$PREFIX$*"
}

Which ()
{
    which "$1" > /dev/null 2>&1
}

Require ()
{
    for tmp in curl
    do
        Which $tmp && return 0
    done

    Die "ERROR: Not any found in PATH: curl"
}

DisplaytHostList ()
{
    tmp="$TMPDIR/$$"

    ${test:+echo} curl --silent \
        --request GET https://api.dynu.com/v2/dns \
        --header "accept: application/json" \
        --header "API-Key: $APIKEY" \
        > "$tmp"

    if Which json_pp ; then
        # Pretty print in separate lines. Comes wth perl(1)
        cat "$tmp" | json_pp -json_opt pretty,canonical
    else
        cat "$tmp"
    fi

    rm -f "$tmp"
}

GetIp ()
{
    curl --silent "$1"
}

SetIp ()
{
    if [ ! "$IP" ]; then
        IP=$(GetIp "$GETIP")
    fi

    DieIfEmpty "$IP" "ERROR: cannot read IP from $GETIP. See --getip"
}

Update ()
{
    Verbose "UPDATE domain $DOMAIN ip $IP id $ID ttl $TTL"

    tmp="$TMPBASE"

    if [ "$test" ]; then
        echo \
        curl --silent \
            --request POST "https://api.dynu.com/v2/dns/$ID" \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "API-Key: $APIKEY" \
            --data "{\"name\": \"$DOMAIN\", \
                    \"ipv4Address\":\"$IP\", \
                    \"ttl\":$TTL, \
                    \"ipv4\":true}"
    else
        curl --silent \
            --request POST "https://api.dynu.com/v2/dns/$ID" \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "API-Key: $APIKEY" \
            --data "{\"name\": \"$DOMAIN\", \
                    \"ipv4Address\":\"$IP\", \
                    \"ttl\":$TTL, \
                    \"ipv4\":true}" \
        > "$tmp"
    fi

    status=1

    if [ -f "$tmp" ] && grep --quiet '200' "$tmp" ; then
        status=0
    fi

    if [ ! "$test" ]; then
        Verbose "STATUS $(cat "$tmp")"
    fi

    return $status
}

UpdateByConfdir ()
{
    if [ ! -d "$CONFDIR" ]; then
        Die "ĆONFDIR not exists: $CONFDIR"
    fi

    # Drop trailing slash
    CONFDIR=${CONFDIR%/}

    for file in $CONFDIR/*.conf
    do
        if [ ! -f "$file" ]; then
            Die "CONF no file: $file"
        fi
    (

        Verbose "CONF read: $file"

        . "$file" || continue

        if [ "$ENABLE" ]; then
            Update
        else
            Verbose "CONF disabled: $file"
        fi
    )
    done
}

# -----------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------

Main ()
{
    while :
    do
        case "$1" in
            -c | --confdir)
                CONFDIR=$2
                shift 2
                ;;
            -d | --domain)
                DOMAIN=$2
                shift 2
                ;;
            -g | --getip)
                GETIP=$2
                shift 2
                ;;
            -h | --help)
                Help
                return 0
                ;;
            -i | --id)
                ID=$2
                shift 2
                ;;
            -I | --ip)
                IP=$2
                shift 2
                ;;
            -k | --apikey)
                APIKEY=$2
                shift 2
                ;;
            -Q | --query)
                query="query"
                shift
                ;;
            -t | --test)
                test="test"
                shift
                ;;
            -T | --ttl)
                TTL=$2
                shift 2
                ;;
            -v | --verbose)
                verbose="verbose"
                shift
                ;;
            -V | --version)
                Version
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                Warn "WARN: Unknon arg: $1"
                break
                ;;
            *)
                break
                ;;
        esac
    done

    if [ "$CONFDIR" ]; then
        SetIp
        UpdateByConfdir
        return $?
    fi

    DieIfEmpty "$APIKEY" "ERROR: no host APIKEY, see --help"

    if [ "$query" ]; then
        DisplaytHostList
        return 0
    fi

    DieIfEmpty "$ID" "ERROR: no host ID, see --help"
    DieIfEmpty "$DOMAIN" "ERROR: no host DOMAIN, See --help"

    SetIp
    Update
}

trap Atexit 0 1 2 3 5 15 19
Require
Main "$@"

# End of file
