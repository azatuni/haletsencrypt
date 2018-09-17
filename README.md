# haletsencrypt
Bash script for installing and renewing lestencrypt ssl cert on haproxy

Before running script you'd have nginx runngin on the same machine as haproxy. Nginx'd have the same document root as defined in DOC_ROOT variable in haletsencrypt.sh script. You can just copy haletsencrypt_nginx.conf to your nginx configuration include directory, usually /etc/nginx/conf.d 
Also you'd do some changes in haproxy configuration. You'd configure haproxy to proxy URI with /.well-known/acme-challenge/ to local nginx.
```
acl is_letsencrypt path_beg -i /.well-known/acme-challenge/
use_backend letsencrypt if is_letsencrypt
```
if you have a force https rewriting then make a exception for letsencrypt verification URI:
```
redirect scheme https code 301 if !{ ssl_fc } !is_letsencrypt
```
Define nginx as backend in backend section:
```
backend letsencrypt
        mode http
        option forwardfor
        option httpclose
        option  http-server-close
        server letsencrypt 127.0.0.1:8080 maxconn 100
```

After then you can define neccessary variables in haletsencrypt.sh and run it. 
