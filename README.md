# package-modsecurity-nginx

Package modsecurity for nginx

## Create a package for debian

Choose «Without docker» or «With docker».  

### Without docker

```
sudo apt install git g++ flex bison curl doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev libssl-dev zlib1g-dev libxslt-dev libgd-dev wget

git clone https://github.com/Alkante35/package-modsecurity-nginx.git
cd package-modsecurity-nginx
./make.sh
```
See below for make.sh parameters.

### With docker

```
git clone https://github.com/Alkante35/package-modsecurity-nginx.git
cd package-modsecurity-nginx/docker
docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) -t build_modsecurity_debian10 .
docker run -v $(pwd)/../:/opt -w /opt/ build_modsecurity_debian10 /opt/make.sh
```
See below for make.sh parameters.


### make.sh parameters

```
Build a deb package of modsecurity for nginx.
./make.sh [-n <NGINX_VERSION>] [-p <PACKAGE_VERSION>]

  -h, --help                            Help
  -n, --nginxVersion=NGINX_VERSION      Set the version of Nginx. Default "1.14.2"
  -p, --packageVersion=PACKAGE_VERSION  Set the vervion of the new package. Default "1.14.2-1"
```
  
Example  
2nd release for nginx 1.14.2
```
./make.sh -n 1.14.2 -p -1.14.2-2
```

## Install the package

Copy libnginx-mod-http-modsecurity_1.14.2-1_amd64.deb on your server.  
Then
```
sudo -s
apt install nginx libyajl2
apt install --no-install-recommends modsecurity-crs
apt install ./libnginx-mod-http-modsecurity_1.14.2-1_amd64.deb
```
## Enable modsecurity

In /etc/nginx/sites-available/...conf, add :  
```
server {
	[...]
	modsecurity on;
	modsecurity_rules_file /etc/modsecurity/main.conf;
	[...]
}
```
In /etc/nginx/nginx.conf, check that you have this :  
```
include /etc/nginx/modules-enabled/*.conf;
```

Add config of modsecurity :  
```
cp /etc/modsecurity/modsecurity.conf-recommended-all /etc/modsecurity/modsecurity.conf
```
Copy rules you want form /usr/share/modsecurity-crs/rules/ in /etc/modsecurity/crs/

activate the module :  
```
sed -i "s|SecRuleEngine DetectionOnly|SecRuleEngine On|" /etc/modsecurity/modsecurity.conf
cd /etc/nginx/modules-enabled
ln -s /usr/share/nginx/modules-available/mod-http-modsecurity.conf 50-mod-http-modsecurity.conf
```
Check the conf  
```
nginx -t
```
or  
```
nginx -R
```
If ok  
```
nginx -s reload
```

## Documentations

For more informations on ModSecurity :  
https://github.com/SpiderLabs/ModSecurity-nginx
https://github.com/SpiderLabs/ModSecurity
