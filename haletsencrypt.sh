#!/bin/bash
#Bash script for installing and renewing lestencrypt ssl cert on haproxy
#Version 1.2
#Author: https://gitlab.com/azatuni

DOMAINS=(
 "example.com"
 "www.example.com"
)

#Email for letsencrypt notifications
EMAIL="info@example.com"
FROM_EMAIL="harenew@example.com"
#Webroot'd be documnet root fot defaul server
WEB_ROOT="/var/www/html/letsencrypt"
#Trhrashhold for renewing cert/certs
EXP_LIMIT_DAYS=40

function get_cert_expr_time () {
NOW_IN_UNIXTIME=`date +%s`
SSL_EXPR_IN_UNIXTIME=$(date -d "`openssl x509 -in $CERT_FILE -text -noout|grep "Not After"|cut -c 25-`" +%s)
UNTIL_SSL_EXPR_IN_UNIXTIME=`expr $SSL_EXPR_IN_UNIXTIME - $NOW_IN_UNIXTIME`
DAYS_UNTIL_EXPR=`expr $UNTIL_SSL_EXPR_IN_UNIXTIME / 86400`
}

function make_pem_file () {
echo -e "Creating $PEM_FILE with latest certs..." 
test -f $CERT_FILE && test -f $KEY_FILE && cat $CERT_FILE $KEY_FILE > $PEM_FILE
}

function try_reload_haproxy () {
echo -e "Reloading haproxy"
/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg && service haproxy reload && echo -e "Haproxy has been reloaded"
}

function report_via_email () {
echo "Subject: $@" | sendmail -f $FROM_EMAIL -s "SSL renew report for $domain"  $EMAIL
}

for domain in "${DOMAINS[@]}"
do	
	CERT_DIR="/etc/letsencrypt/live/`ls /etc/letsencrypt/live/ |grep ^$domain`"
	CERT_FILE="$CERT_DIR/fullchain.pem"
	KEY_FILE="$CERT_DIR/privkey.pem"
	PEM_FILE="/etc/haproxy/certs/$domain.pem"
	if [ ! -f "$CERT_FILE" ]
		then	echo "Creating certificate for domain $domain."
			letsencrypt certonly --webroot --webroot-path $WEB_ROOT --email $EMAIL --agree-tos -d $domain --server https://acme-v02.api.letsencrypt.org/directory
			make_pem_file && try_reload_haproxy
		else	get_cert_expr_time
    			if [ "$DAYS_UNTIL_EXPR" -gt "$EXP_LIMIT_DAYS" ]
				then	echo "$domain, no need for renewal "$DAYS_UNTIL_EXPR"  days left."
    				else	echo "The certificate for $domain is about to expire soon."
     		 			echo "Starting Let's Encrypt renewal script..."
					certbot certonly --webroot --webroot-path $WEB_ROOT  --email $EMAIL --agree-tos -d  $domain --server https://acme-v02.api.letsencrypt.org/directory -n --force-renew
					if [ $? == 0 ]
						then	make_pem_file && try_reload_haproxy && report_via_email
      							echo "Successfully renewed SSL cert for $domain"
							report_via_email Successfully renewed SSL cert for $domain
						else	echo "Failed to renew SSL cert for $domain"
							report_via_email Failed to renew SSL cert for $domain
					fi
    			fi
 	fi
done
