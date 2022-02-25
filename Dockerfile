#FROM elmarit/harbour:3.2 as builder
FROM fastcgi

# Build DataWharf
WORKDIR /src
RUN mkdir -p build/lin64/gcc/release/
ENV EXEName FCGIDataWharf
ENV SiteRootFolder /var/www/Harbour_websites/fcgi_DataWharf/
RUN  hbmk2 DataWharf_linux.hbp -w3 -static

RUN a2enmod rewrite
RUN mkdir -p /var/www/Harbour_websites/fcgi_DataWharf/apache-logs/

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

ADD ./FilesForPublishedWebsites/LinuxApache2/DataWharf.conf /etc/apache2/sites-enabled/000-default.conf


COPY ./FilesForPublishedWebsites/backend /var/www/Harbour_websites/fcgi_DataWharf/backend
RUN cp /src/build/lin64/gcc/release/FCGIDataWharf.exe /var/www/Harbour_websites/fcgi_DataWharf/backend/
COPY ./FilesForPublishedWebsites/website /var/www/Harbour_websites/fcgi_DataWharf/website

RUN chown -R www-data:www-data /var/www/Harbour_websites

EXPOSE 80 
CMD apache2ctl -D FOREGROUND