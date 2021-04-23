#!/bin/bash
# https://help.launchpad.net/API/SigningRequests
# https://api.launchpad.net/

oauth_consumer_key=${oauth_consumer_key:=test}
LAUNCHPAD_API="${LAUNCHPAD_API:=https://api.launchpad.net/}"

get_token()
{
    echo "oauth_consumer_key=${oauth_consumer_key}"
    oauth=$(http --form post https://launchpad.net/+request-token oauth_consumer_key="$oauth_consumer_key" oauth_signature_method=PLAINTEXT oauth_signature="&")
    echo "$oauth"

    eval "${oauth/&*/}"
    echo "oauth_token=${oauth_token:=}"

    eval "${oauth/*&/}"
    echo "oauth_token_secret=${oauth_token_secret:=}"

    echo "Please open https://launchpad.net/+authorize-token?oauth_token=$oauth_token to authorize the token."

    while :; do
        body=$(http --form post https://launchpad.net/+access-token oauth_token="$oauth_token" oauth_consumer_key="$oauth_consumer_key" oauth_signature_method=PLAINTEXT oauth_signature="&$oauth_token_secret")
        if [ "$body" = "Request token has not yet been reviewed. Try again later." ]; then
            # Timed out after 900 seconds.
            echo "Wait for 5 seconds."
            sleep 5
        elif [ "$body" = "Invalid OAuth signature." ]; then
            break
        else
            echo "$body"
            oauth=${body/&lp.context=*/}
            eval "${oauth/&*/}"
            echo "oauth_token=${oauth_token}"

            eval "${oauth/*&/}"
            echo "oauth_token_secret=${oauth_token_secret}"
            break
        fi
    done
}

parse_api()
{
    if [ -z "$1" ]; then
        return
    fi
    case "$1" in
        (${LAUNCHPAD_API}*)
            echo "$1"
            ;;
        (devel/*)
            echo "${LAUNCHPAD_API}$1"
            ;;
        (/devel/*)
            echo "${LAUNCHPAD_API}${1:1}"
            ;;
        (/*)
            echo "${LAUNCHPAD_API}devel$1"
            ;;
        (*)
            echo "${LAUNCHPAD_API}devel/$1"
            ;;
    esac
}

get_api()
{
    api=$(parse_api "$1")
    if [ -z "$api" ]; then
        return
    fi
    shift
    http --check-status --ignore-stdin --follow GET "$api" \
        'OAuth realm'=="${LAUNCHPAD_API}" \
        oauth_consumer_key=="${oauth_consumer_key}" \
        oauth_nonce=="$(date +%s)" \
        oauth_signature=="&${oauth_token_secret}" \
        oauth_signature_method=="PLAINTEXT" \
        oauth_timestamp=="$(date +%s)" \
        oauth_token=="${oauth_token}" \
        oauth_version=="1.0" \
        "$@"
}

post_api()
{
    api=$(parse_api "$1")
    if [ -z "$api" ]; then
        return
    fi
    shift
    http --check-status --ignore-stdin --form POST "$api" \
        'OAuth realm'="${LAUNCHPAD_API}/" \
        oauth_consumer_key="${oauth_consumer_key}" \
        oauth_nonce="$(date +%s)" \
        oauth_signature="&${oauth_token_secret}" \
        oauth_signature_method="PLAINTEXT" \
        oauth_timestamp="$(date +%s)" \
        oauth_token="${oauth_token}" \
        oauth_version="1.0" \
        "$@"
}

if [ -f "$HOME/.config/launchpad/${oauth_consumer_key}" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.config/launchpad/${oauth_consumer_key}"
else
    get_token
    mkdir -p "$HOME/.config/launchpad"
    cat > "$HOME/.config/launchpad/${oauth_consumer_key}" <<ENDLINE
#!/bin/bash

export oauth_token="${oauth_token}"
export oauth_token_secret="${oauth_token_secret}"
ENDLINE
fi

case "$1" in
    ('')
        get_api devel/people/+me
        ;;
    ("get"|"GET")
        shift
        get_api "$@"
        ;;
    ("post"|"POST")
        shift
        post_api "$@"
        ;;
    (*)
        echo "usage: $0 [get|post] API_URL [param1==value1|field1=value1]... # Check the REQUEST_ITEM part in the httpie manual for details."
        ;;
esac
