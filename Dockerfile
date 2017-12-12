FROM centos:7
EXPOSE 80

# update and install OS packages
RUN yum update -y
RUN yum groupinstall -y "Development Tools"
RUN yum install -y httpd httpd-devel pcre pcre-devel libxml2 libxml2-devel curl curl-devel openssl openssl-devel

# checkout and compile ModSecurity for nginx
WORKDIR /usr/src
RUN git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git
WORKDIR /usr/src/ModSecurity
RUN ./autogen.sh
RUN ./configure --enable-standalone-module --disable-mlogc
RUN make

# compile and install nginx with ModSecurity
WORKDIR /usr/src
ADD nginx-1.10.3.tar.gz /usr/src/
RUN groupadd -r nginx
RUN useradd -r -g nginx -s /sbin/nologin -M nginx
WORKDIR /usr/src/nginx-1.10.3
RUN ./configure --user=nginx --group=nginx --add-module=/usr/src/ModSecurity/nginx/modsecurity --with-http_ssl_module
RUN make
RUN make install
RUN /usr/local/nginx/sbin/nginx -t

# configure nginx
RUN cp /usr/src/ModSecurity/unicode.mapping /usr/local/nginx/conf/
ADD nginx.conf  /usr/local/nginx/conf/
ADD modsec_includes.conf /usr/local/nginx/conf/
ADD modsecurity.conf /usr/local/nginx/conf/

# configure modsec

ADD owasp-modsecurity-crs/ /usr/local/nginx/conf/owasp-modsecurity-crs
ADD additional-rules/ /usr/local/nginx/conf/additional-rules
ADD crs-setup.conf /usr/local/nginx/conf/owasp-modsecurity-crs/
WORKDIR /usr/local/nginx/conf/owasp-modsecurity-crs/rules
RUN mv REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
RUN mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# check the config
RUN /usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf

# start nginx when this contain is run
CMD /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf

