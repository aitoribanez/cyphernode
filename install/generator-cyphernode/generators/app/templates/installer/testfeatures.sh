#!/bin/sh

apk add --update --no-cache openssl curl > /dev/null

. keys.properties

checkgatekeeper() {
  echo -e "\r\n\e[1;36mTesting Gatekeeper...\e[0;32m" > /dev/console

  local rc
  local id="001"
  local k
  eval k='$ukey_'$id

  local h64=$(echo "{\"alg\":\"HS256\",\"typ\":\"JWT\"}" | base64)

  # Let's test expiration: 1 second in payload, request 2 seconds later

  local p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+1))}" | base64)
  local s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  local token="$h64.$p64.$s"

  echo -e "  Sleeping 2 seconds... " > /dev/console
  sleep 2

  echo "  Testing expired request... " > /dev/console
  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/getblockinfo)
  [ "${rc}" -ne "403" ] && return 10

  # Let's test authentication (signature)

  p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  token="$h64.$p64.a$s"

  echo "  Testing bad signature... " > /dev/console
  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/getblockinfo)
  [ "${rc}" -ne "403" ] && return 30

  # Let's test authorization (action access for groups)

  token="$h64.$p64.$s"

  echo "  Testing watcher trying to do a spender action... " > /dev/console
  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/getbalance)
  [ "${rc}" -ne "403" ] && return 40

  id="002"
  eval k='$ukey_'$id
  p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  token="$h64.$p64.$s"

  echo "  Testing spender trying to do an internal action call... " > /dev/console
  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/conf)
  [ "${rc}" -ne "403" ] && return 50


  id="003"
  eval k='$ukey_'$id
  p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  token="$h64.$p64.$s"

  echo "  Testing admin trying to do an internal action call... " > /dev/console
  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/conf)
  [ "${rc}" -ne "403" ] && return 60

  echo -e "\e[1;36mGatekeeper rocks!" > /dev/console

  return 0
}

checkpycoin() {
  echo -en "\r\n\e[1;36mTesting Pycoin... " > /dev/console
  local rc
  local id="002"
  local k
  eval k='$ukey_'$id

  local h64=$(echo "{\"alg\":\"HS256\",\"typ\":\"JWT\"}" | base64)

  local p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  local s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  local token="$h64.$p64.$s"

  rc=$(curl -H "Content-Type: application/json" -d "{\"pub32\":\"upub5GtUcgGed1aGH4HKQ3vMYrsmLXwmHhS1AeX33ZvDgZiyvkGhNTvGd2TA5Lr4v239Fzjj4ZY48t6wTtXUy2yRgapf37QHgt6KWEZ6bgsCLpb\",\"path\":\"0/25-30\"}" -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/derivepubpath)
  [ "${rc}" -ne "200" ] && return 100

  echo -e "\e[1;36mPycoin rocks!" > /dev/console

  return 0
}

checkots() {
  echo -en "\r\n\e[1;36mTesting OTSclient... " > /dev/console
  local rc
  local id="002"
  local k
  eval k='$ukey_'$id

  local h64=$(echo "{\"alg\":\"HS256\",\"typ\":\"JWT\"}" | base64)

  local p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  local s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  local token="$h64.$p64.$s"

  rc=$(curl -s -H "Content-Type: application/json" -d '{"hash":"123","callbackUrl":"http://callback"}' -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/ots_stamp)
  echo "${rc}" | grep "Invalid hash 123 for sha256" > /dev/null
  [ "$?" -ne "0" ] && return 200

  echo -e "\e[1;36mOTSclient rocks!" > /dev/console

  return 0
}

checkbitcoinnode() {
  echo -en "\r\n\e[1;36mTesting Bitcoin... " > /dev/console
  local rc
  local id="002"
  local k
  eval k='$ukey_'$id

  local h64=$(echo "{\"alg\":\"HS256\",\"typ\":\"JWT\"}" | base64)

  local p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  local s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  local token="$h64.$p64.$s"

  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/getbestblockhash)
  [ "${rc}" -ne "200" ] && return 300

  echo -e "\e[1;36mBitcoin node rocks!" > /dev/console

  return 0
}

checklnnode() {
  echo -en "\r\n\e[1;36mTesting Lightning... " > /dev/console
  local rc
  local id="002"
  local k
  eval k='$ukey_'$id

  local h64=$(echo "{\"alg\":\"HS256\",\"typ\":\"JWT\"}" | base64)

  local p64=$(echo "{\"id\":\"$id\",\"exp\":$((`date +"%s"`+10))}" | base64)
  local s=$(echo -n "$h64.$p64" | openssl dgst -hmac "$k" -sha256 -r | cut -sd ' ' -f1)
  local token="$h64.$p64.$s"

  rc=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" --cacert /cert.pem https://gatekeeper/ln_getinfo)
  [ "${rc}" -ne "200" ] && return 400

  echo -e "\e[1;36mLN node rocks!" > /dev/console

  return 0
}

checkservice() {
  echo -e "\r\n\e[1;36mTesting if Cyphernode is up and running... \e[0;36mI will keep trying during up to 5 minutes to give time to Docker to deploy everything...\e[0;32m" > /dev/console

  local outcome
  local returncode=0
  local endtime=$(($(date +%s) + 300))
  local result

  while :
  do
    outcome=0
    for container in gatekeeper proxy proxycron pycoin <%= (features.indexOf('otsclient') != -1)?'otsclient ':'' %>bitcoin  <%= (features.indexOf('lightning') != -1)?'lightning ':'' %>; do
      echo -e "  \e[0;32mVerifying \e[0;33m${container}\e[0;32m..." > /dev/console
      (ping -c 10 ${container} 2> /dev/null | grep "0% packet loss" > /dev/null) &
      eval ${container}=$!
    done
    for container in gatekeeper proxy proxycron pycoin <%= (features.indexOf('otsclient') != -1)?'otsclient ':'' %>bitcoin  <%= (features.indexOf('lightning') != -1)?'lightning ':'' %>; do
      eval wait '$'${container} ; returncode=$? ; outcome=$((${outcome} + ${returncode}))
      eval c_${container}=${returncode}
    done

    # If '0% packet loss' everywhere or 5 minutes passed, we get out of this loop
    ([ "${outcome}" -eq "0" ] || [ $(date +%s) -gt ${endtime} ]) && break

    echo -e "\e[1;31mCyphernode still not ready, will retry every 5 seconds for 5 minutes ($((${endtime} - $(date +%s))) seconds left)." > /dev/console

    sleep 5
  done

  #  "containers": [
  #    { "name": "gatekeeper", "active":true },
  #    { "name": "proxy", "active":true },
  #    { "name": "proxycron", "active":true },
  #    { "name": "pycoin", "active":true },
  #    { "name": "otsclient", "active":true },
  #    { "name": "bitcoin", "active":true },
  #    { "name": "lightning", "active":true }
  #  ]
  for container in gatekeeper proxy proxycron pycoin <%= (features.indexOf('otsclient') != -1)?'otsclient ':'' %>bitcoin  <%= (features.indexOf('lightning') != -1)?'lightning ':'' %>; do
    [ -n "${result}" ] && result="${result},"
    result="${result}{\"name\":\"${container}\",\"active\":"
    eval "returncode=\$c_${container}"
    if [ "${returncode}" -eq "0" ]; then
      result="${result}true}"
    else
      result="${result}false}"
    fi
  done

  result="\"containers\":[${result}]"

  echo $result

  return ${outcome}
}

timeout_feature() {
  local testwhat=${1}
  local returncode
  local endtime=$(($(date +%s) + 120))

  while :
  do
    eval ${testwhat}
    returncode=$?

    # If no error or 2 minutes passed, we get out of this loop
    ([ "${returncode}" -eq "0" ] || [ $(date +%s) -gt ${endtime} ]) && break

    echo -e "\e[1;31mMaybe it's too early, I'll retry every 5 seconds for 2 minutes ($((${endtime} - $(date +%s))) seconds left)." > /dev/console

    sleep 5
  done

  return ${returncode}
}

feature_status() {
  local returncode=${1}
  local errormsg=${2}

  [ "${returncode}" -eq "0" ] && echo "true"
  [ "${returncode}" -ne "0" ] && echo "false" && echo -e "\e[1;31m${errormsg}" > /dev/console
}

# /proxy/installation.json will contain something like that:
#{
#  "containers": [
#    { "name": "gatekeeper", "active":true },
#    { "name": "proxy", "active":true },
#    { "name": "proxycron", "active":true },
#    { "name": "pycoin", "active":true },
#    { "name": "otsclient", "active":true },
#    { "name": "bitcoin", "active":true },
#    { "name": "lightning", "active":true }
#  ],
#  "features": [
#    { "name": "gatekeeper", "working":true },
#    { "name": "pycoin", "working":true },
#    { "name": "otsclient", "working":true },
#    { "name": "bitcoin", "working":true },
#    { "name": "lightning", "working":true }
#  ]
#}

# Let's first see if everything is up.

result=$(checkservice)
returncode=$?
if [ "${returncode}" -ne "0" ]; then
  echo -e "\e[1;31mCyphernode could not fully start properly within 5 minutes." > /dev/console
else
  echo -e "\e[1;36mCyphernode seems to be correctly deployed.  Let's run more thourough tests..." > /dev/console
fi

# Let's now check each feature fonctionality...
#  "features": [
#    { "name": "gatekeeper", "working":true },
#    { "name": "pycoin", "working":true },
#    { "name": "otsclient", "working":true },
#    { "name": "bitcoin", "working":true },
#    { "name": "lightning", "working":true }
#  ]

result="${result},\"features\":[{\"name\":\"gatekeeper\",\"working\":"
timeout_feature checkgatekeeper
returncode=$?
result="${result}$(feature_status ${returncode} 'Gatekeeper error!')}"

result="${result},{\"name\":\"pycoin\",\"working\":"
timeout_feature checkpycoin
returncode=$?
result="${result}$(feature_status ${returncode} 'Pycoin error!')}"

<% if (features.indexOf('otsclient') != -1) { %>
result="${result},{\"name\":\"otsclient\",\"working\":"
timeout_feature checkots
returncode=$?
result="${result}$(feature_status ${returncode} 'OTSclient error!')}"
<% } %>

result="${result},{\"name\":\"bitcoin\",\"working\":"
timeout_feature checkbitcoinnode
returncode=$?
result="${result}$(feature_status ${returncode} 'Bitcoin error!')}"

<% if (features.indexOf('lightning') != -1) { %>
result="${result},{\"name\":\"lightning\",\"working\":"
timeout_feature checklnnode
returncode=$?
result="${result}$(feature_status ${returncode} 'Lightning error!')}"
<% } %>

result="{${result}]}"

echo "${result}" > /gatekeeper/installation.json

echo -e "\r\n\e[1;32mTests finished.\e[0m" > /dev/console
