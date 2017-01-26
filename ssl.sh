#!/bin/sh -e

cd `dirname $0`

. ./srl.conf

# 証明書処理 
if [ -d ./certificates ]; then
    ./lego/lego --path ./ --webroot "$DOCUMENTROOT" --email "$SSL_MAILADDR" --domains "$SNI_DOMAIN" --accept-tos renew 
    renew=1
else
    ./lego/lego --path ./ --webroot "$DOCUMENTROOT" --email "$SSL_MAILADDR" --domains "$SNI_DOMAIN" --accept-tos run 
    renew=0
fi
IFS='
'
flag="server_crt"
for line in `cat certificates/${SNI_DOMAIN}.crt`
do
    if [ "$flag" == "server_crt" ]; then
        server_crt="$server_crt$line\n"
    else
        chain_crt="$chain_crt$line\n"
    fi
    if echo "$line" | grep -q "END CERTIFICATE" ; then
        flag="chain_crt"
    fi
done

get_token () {
    body=$(curl -s -b cookie -c cookie "$1")
    token=$(echo "$body" | grep 'name="Token"' | head -n1 | perl -pe 's/.+value="(.+)" \/>$/$1/g;')
}

echo "Login"
get_token "https://secure.sakura.ad.jp/rscontrol/"
curl -qs -b cookie -c cookie -L -X POST https://secure.sakura.ad.jp/rscontrol/ \
    -d "Token=$token&Submit=index&domain=${ACCOUNT}.sakura.ne.jp&password=${PASSWD}" \
    -o /dev/null 

if [ $renew -eq 1 ] ; then
    get_token "https://secure.sakura.ad.jp/rscontrol/rs/ssl?SNIDomain=${SNI_DOMAIN}"
    curl -qs -b cookie -c cookie -L -X POST "https://secure.sakura.ad.jp/rscontrol/rs/ssl?SNIDomain=${SNI_DOMAIN}" \
    -d "Token=$token&Target=new&Submit_newdir=秘密鍵を含む新しい設定の作成" \
    -o /dev/null
fi

echo "Install Key"
get_token "https://secure.sakura.ad.jp/rscontrol/rs/ssl?SNIDomain=${SNI_DOMAIN}"
curl -qs -b cookie -c cookie -X POST "https://secure.sakura.ad.jp/rscontrol/rs/ssl?SNIDomain=${SNI_DOMAIN}" \
    -F Token=$token \
    -F Submit_upload="秘密鍵をアップロードする" \
    -F "file=@certificates/${SNI_DOMAIN}.key;type=application/x-x509-ca-cer" -o /dev/null

echo "Install Certificate"
get_token "https://secure.sakura.ad.jp/rscontrol/rs/ssl?Install=1&SNIDomain=${SNI_DOMAIN}"
curl -qs -b cookie -c cookie -X POST "https://secure.sakura.ad.jp/rscontrol/rs/ssl?Install=1&SNIDomain=${SNI_DOMAIN}" \
    -d "Token=$token&Cert=$(echo -e "$server_crt" | perl -MURI::Escape -lne 'print uri_escape($_)')&Submit_install&Submit_install.x=35&Submit_install.y=10" \
    -o /dev/null

echo "Install Chain Certificate"
get_token "https://secure.sakura.ad.jp/rscontrol/rs/ssl?CACert=1&SNIDomain=${SNI_DOMAIN}"
curl -qs  -b cookie -c cookie -X POST "https://secure.sakura.ad.jp/rscontrol/rs/ssl?CACert=1&SNIDomain=${SNI_DOMAIN}" \
    -d "Token=$token&Cert=$(echo -e "$chain_crt" | perl -MURI::Escape -lne 'print uri_escape($_)')&Submit_cacert.x=6&Submit_cacert.y=12" \
    -o /dev/null

if [ $renew -eq 1 ] ; then
    echo "apply new certificate"
    get_token "https://secure.sakura.ad.jp/rscontrol/rs/ssl?SNIDomain=${SNI_DOMAIN}"
    curl -qs -b cookie -c cookie -X POST "https://secure.sakura.ad.jp/rscontrol/rs/ssl?SNIDomain=${SNI_DOMAIN}" \
    -d "Token=$token&Submit=applynew" \
    -o /dev/null
fi
