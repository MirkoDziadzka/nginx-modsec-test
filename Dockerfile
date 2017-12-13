FROM centos:7
EXPOSE 80

# update and install OS packages
RUN yum update -y
RUN yum groupinstall -y "Development Tools"
RUN yum install -y httpd httpd-devel pcre pcre-devel libxml2 libxml2-devel curl curl-devel openssl openssl-devel 
RUN yum install -y GeoIP-devel yajl-devel

# Make debugging easier ...
WORKDIR /usr/src
# ADD Dockerfile /usr/src/

# checkout and compile ModSecurity v3 
WORKDIR /usr/src
RUN git clone -b v3/master https://github.com/SpiderLabs/ModSecurity.git
WORKDIR /usr/src/ModSecurity
RUN git submodule init
RUN git submodule update
RUN ./build.sh
RUN ./configure 
RUN make
RUN make install


# checkout modsec-connector
WORKDIR /usr/src
RUN git clone https://github.com/SpiderLabs/ModSecurity-nginx.git

WORKDIR /usr/src
ADD nginx-1.12.2.tar.gz /usr/src/
RUN groupadd -r nginx
RUN useradd -r -g nginx -s /sbin/nologin -M nginx
WORKDIR /usr/src/nginx-1.12.2
RUN ./configure --user=nginx --group=nginx --add-module=/usr/src/ModSecurity-nginx --with-http_ssl_module
RUN make
RUN make install
RUN /usr/local/nginx/sbin/nginx -V
RUN /usr/local/nginx/sbin/nginx -t


# configure nginx
ADD modsecurity.conf /usr/local/nginx/conf/
ADD nginx.conf  /usr/local/nginx/conf/
ADD owasp-modsecurity-crs/ /usr/local/nginx/conf/owasp-modsecurity-crs
ADD additional-rules/ /usr/local/nginx/conf/additional-rules
ADD crs-setup.conf /usr/local/nginx/conf/owasp-modsecurity-crs/

# check the config
# RUN /usr/local/nginx/sbin/nginx -V
# RUN /usr/local/nginx/sbin/nginx -T

WORKDIR /usr/src/ModSecurity/test
RUN ./unit_tests
RUN env TERM=vt100 ./regression_tests 

# start nginx when this contain is run
CMD /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf

