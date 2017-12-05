FROM centos:7
EXPOSE 80

RUN yum update -y
RUN yum groupinstall -y "Development Tools"
RUN yum install -y httpd httpd-devel pcre pcre-devel libxml2 libxml2-devel curl curl-devel openssl openssl-devel

WORKDIR /usr/src
RUN git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git
WORKDIR /usr/src/ModSecurity
RUN ./autogen.sh
RUN ./configure --enable-standalone-module --disable-mlogc
RUN make

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
# ADD nginx.service /lib/systemd/system/

COPY nginx.conf  /usr/local/nginx/conf/nginx.conf
ADD modsec_includes.conf /usr/local/nginx/conf/
RUN cp /usr/src/ModSecurity/modsecurity.conf-recommended /usr/local/nginx/conf/modsecurity.conf
RUN cp /usr/src/ModSecurity/unicode.mapping /usr/local/nginx/conf/
RUN sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /usr/local/nginx/conf/modsecurity.conf

ADD owasp-modsecurity-crs/ /usr/local/nginx/conf/owasp-modsecurity-crs
WORKDIR /usr/local/nginx/conf/owasp-modsecurity-crs
RUN mv crs-setup.conf.example crs-setup.conf
WORKDIR /usr/local/nginx/conf/owasp-modsecurity-crs/rules
RUN mv REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
RUN mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

RUN /usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
CMD /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf






