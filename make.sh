#!/bin/bash
# 2020-12-03 APU

# https://github.com/SpiderLabs/ModSecurity
# https://github.com/SpiderLabs/ModSecurity-nginx
# https://blog.knoldus.com/create-a-debian-package-using-dpkg-deb-tool/
# apt install git g++ flex bison curl doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev libssl-dev zlib1g-dev libxslt-dev libgd-dev wget

nginxVersion="1.14.2"
packageVersion="$nginxVersion-1"

show_usage() {
	cat <<EOF
Build a deb package of modsecurity for nginx.
$0 [-n <NGINX_VERSION>] [-p <PACKAGE_VERSION>]

  -h, --help                            Help
  -n, --nginxVersion=NGINX_VERSION      Set the version of Nginx. Default "$nginxVersion"
  -p, --packageVersion=PACKAGE_VERSION  Set the vervion of the new package. Default "$packageVersion"
EOF
	exit
}

if [ "$#" -gt 0 ]; then
	while [ ! -z "$1" ];do
		case "$1" in
			-h|--help)
				show_usage
			;;
			-n|--nginxVersion)
				shift
				nginxVersion="$1"
			;;
			-p|--packageVersion)
				shift
				packageVersion="$1"
			;;
			*)
				echo "Incorrect input provided"
				show_usage
		esac
	shift
	done
fi

set -euo pipefail

packageName="libnginx-mod-http-modsecurity_${packageVersion}_amd64"

#if [[ -d work ]]; then
#	rm -rf work
#fi
mkdir -p work
cd work
workDir=$(pwd)

if [ -d "${workDir}/${packageName}" ]; then
	rm -rf "${workDir}/${packageName}"
fi
mkdir -p ${workDir}/${packageName}/usr/local/

if [ ! -d ModSecurity ]; then
	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
fi
cd ModSecurity
git checkout .
git submodule init 
git submodule update
git pull

export DESTDIR=${workDir}/${packageName}
set +e
make clean
set -e
./build.sh 
./configure
make
make install

if [ ! -d ModSecurity-nginx ]; then
	git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
fi
cd ModSecurity-nginx
git checkout .
git pull

#cd ..
cd ${workDir}/ModSecurity

# we fix path
sed -i "s|ngx_feature_path=.*$|ngx_feature_path=\"${workDir}/${packageName}/usr/local/modsecurity/include\"|g" ModSecurity-nginx/config
sed -i "s|ngx_feature_libs=\"-Wl,-rpath,.*$|ngx_feature_libs=\"-Wl,-rpath,/usr/local/modsecurity/lib -L${workDir}/${packageName}/usr/local/modsecurity/lib -lmodsecurity\"|g" ModSecurity-nginx/config

if [ ! -d "nginx-${nginxVersion}" ]; then
	if [ ! -f "nginx-${nginxVersion}.tar.gz" ]; then
		wget "http://nginx.org/download/nginx-${nginxVersion}.tar.gz" -O "nginx-${nginxVersion}.tar.gz"
	fi
	tar -xvzmf "nginx-${nginxVersion}.tar.gz"
	#rm nginx-*.tar.gz
fi
cd "nginx-${nginxVersion}"

./configure  --prefix=${workDir}/${packageName}/usr/share/nginx \
	--add-dynamic-module=../ModSecurity-nginx \
	--with-cc-opt="-g -O2 -fdebug-prefix-map=/build/nginx-Cjs4TR/nginx-${nginxVersion}=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2" \
	--with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
	--prefix=/usr/share/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--http-log-path=/var/log/nginx/access.log \
	--error-log-path=/var/log/nginx/error.log \
	--lock-path=/var/lock/nginx.lock \
	--pid-path=/run/nginx.pid \
	--modules-path=/usr/lib/nginx/modules \
	--http-client-body-temp-path=/var/lib/nginx/body \
	--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
	--http-proxy-temp-path=/var/lib/nginx/proxy \
	--http-scgi-temp-path=/var/lib/nginx/scgi \
	--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
	--with-debug \
	--with-pcre-jit \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_realip_module \
	--with-http_auth_request_module \
	--with-http_v2_module \
	--with-http_dav_module \
	--with-http_slice_module \
	--with-threads \
	--with-http_addition_module \
	--with-http_flv_module \
	--with-http_geoip_module=dynamic \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_image_filter_module=dynamic \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_sub_module \
	--with-http_xslt_module=dynamic \
	--with-mail=dynamic \
	--with-mail_ssl_module \
	--with-stream=dynamic \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module

make modules
cp -ra $workDir/../files/* $workDir/${packageName}/
sed -i "s|NGINXVERSION|${nginxVersion}|g" $workDir/${packageName}/DEBIAN/control
sed -i "s|PACKAGEVERSION|${packageVersion}|g" $workDir/${packageName}/DEBIAN/control
chmod -R 755 $workDir/${packageName}/DEBIAN/
mkdir -p $workDir/${packageName}/usr/share/nginx/modules/
cp objs/ngx_http_modsecurity_module.so $workDir/${packageName}/usr/share/nginx/modules/

rm -r $workDir/${packageName}/usr/local/modsecurity/include
rm -r $workDir/${packageName}/usr/local/modsecurity/lib/pkgconfig
rm -r $workDir/${packageName}/usr/local/modsecurity/lib/libmodsecurity.{a,la}

SUDO=''
if [[ $EUID != 0 ]]; then
	if [[ "$(which sudo)" != "" ]]; then
		SUDO='sudo'
	else
		echo "Please install sudo or run $0 as root!"
		exit 0
	fi
fi
$SUDO chown -R root:root $workDir/${packageName}/*

# build package
# https://blog.knoldus.com/create-a-debian-package-using-dpkg-deb-tool/
cd $workDir
dpkg-deb --build $packageName
mv ${packageName}.deb ..

