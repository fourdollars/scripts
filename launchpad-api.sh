#!/bin/bash
# https://help.launchpad.net/API/SigningRequests

echo "oauth_consumer_key=${oauth_consumer_key:=test}"
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
