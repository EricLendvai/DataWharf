#To take advantage of Docker caching, we are using the same instructions as other .devcontainer/Dockerfile until the "RUN ldconfig"
FROM ubuntu:22.04

## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Used by running apps to detect if inside a docker container. Testing for existence of /.dockerenv may not always work.
ENV InDocker=True

RUN apt-get update && apt-get install -y apt-utils

# Run update again to work around git install failure introduced around April 2023
RUN apt-get update

RUN apt-get install -y \
        libfcgi-dev \
        libapache2-mod-fcgid \
        git \
        build-essential \
        unixodbc-dev \
        apache2 \
        libapache2-mod-fcgid \
        libgpm2 \
        gnupg \
        wget \
        psmisc \
        libcurl4-openssl-dev

# Had to run the following dependency install separatly
RUN apt-get install -y libssl-dev

# install harbour from src
RUN mkdir /src
WORKDIR /src
RUN git clone --branch master https://github.com/harbour/core.git harbour
WORKDIR /src/harbour
ENV HB_WITH_CURL=/usr/include/x86_64-linux-gnu/
ENV HB_WITH_OPENSSL=/usr/include/openssl/

# Will request the make app to use up to 8 core.
RUN make -j 8 install

#To fix symlinks
RUN ldconfig

#- RUN chmod -R a+rwx /src

# Instead of installing PostgreSQL inside the container, to make it easier to develop in both Windows (or Mac) and Docker (Ubuntu)
#  It is preferable to install PostgreSQL on the Host and access it from within the container.

#   # install Postgresql 
#   RUN apt-get -y install postgresql \
#           postgresql-contrib \
#           odbc-postgresql
#   
#   # Run the rest of the commands as the ``postgres`` user when it was ``apt-get installed``
#   USER postgres
#   
#   # Create a PostgreSQL role named ``datawharf`` with ``mypassord`` as the password and
#   # then create a database `DataWharf` owned by the ``datawharf`` role.
#   RUN    /etc/init.d/postgresql start &&\
#       psql --command "CREATE USER datawharf WITH SUPERUSER PASSWORD 'mypassord';" &&\
#       createdb -O datawharf DataWharf &&\
#       psql --dbname DataWharf --command "CREATE EXTENSION pgcrypto;"

# install Postgresql odbc driver
RUN apt-get -y install odbc-postgresql

#Required for the a2enmod
USER root 

RUN a2enmod rewrite
RUN mkdir -p /var/www/Harbour_websites/fcgi_DataWharf/apache-logs/

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

COPY ./FilesForPublishedWebsites/LinuxApache2/DataWharf.conf /etc/apache2/sites-enabled/000-default.conf
COPY ./FilesForPublishedWebsites/LinuxApache2/fcgid.conf /etc/apache2/mods-available/
COPY ./FilesForPublishedWebsites/LinuxApache2/apache2.conf /etc/apache2/

COPY ./FilesForPublishedWebsites/backend  /var/www/Harbour_websites/fcgi_DataWharf/backend

#Fake command to force not using a cache from this point on.
COPY ./.devcontainer/config*.txt /var/www/Harbour_websites/fcgi_DataWharf/backend/
#COPY ./FilesForPublishedWebsites/backend/config_docker.txt /var/www/Harbour_websites/fcgi_DataWharf/backend/config.txt


#RUN cp /src/build/lin64/gcc/release/FCGIDataWharf.exe /var/www/Harbour_websites/fcgi_DataWharf/backend/
COPY ./FilesForPublishedWebsites/website /var/www/Harbour_websites/fcgi_DataWharf/website

RUN chown -R www-data:www-data /var/www/Harbour_websites

RUN update-rc.d apache2  defaults

#   RUN update-rc.d postgresql  defaults


# To make it possible to Delta/Load Datadictionary install additional ODBC drivers
RUN apt-get update
RUN apt-get -y install curl

# Install MSSQL odbc driver
WORKDIR ~
RUN apt-get update && apt-get install -y lsb-release && apt-get clean all
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18
#RUN echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
ENV PATH="${PATH}:/opt/mssql-tools18/bin"


# Install mariadb odbc driver
RUN apt-get -y install odbc-mariadb

# Install MySQL odbc driver
WORKDIR /etc
RUN rm -f ./mysql-community-client-plugins.deb
RUN wget -O ./mysql-community-client-plugins.deb  https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-client-plugins_8.0.33-1ubuntu22.04_amd64.deb
RUN apt install ./mysql-community-client-plugins.deb
RUN rm -f ./mysqlodbc.deb
RUN wget -O ./mysqlodbc.deb https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc_8.0.33-1ubuntu22.04_amd64.deb
RUN apt install ./mysqlodbc.deb

# Install Oracle instant client and odbc driver (client is a dependency of the odbc driver)
WORKDIR /etc
RUN rm -f ./oracle-instantclient-basiclite.rpm
RUN apt-get install -y libaio1 alien
RUN wget -O ./oracle-instantclient-basiclite.rpm https://download.oracle.com/otn_software/linux/instantclient/2340000/oracle-instantclient-basiclite-23.4.0.24.05-1.el9.x86_64.rpm
RUN alien -i --scripts oracle-instantclient-basiclite.rpm
#RUN rm -f oracle-instantclient-basiclite.rpm
ENV LD_LIBRARY_PATH="/usr/lib/oracle/23/client64/lib:${LD_LIBRARY_PATH}"

RUN rm -f ./oracle-instantclient-odbc.rpm
RUN wget -O ./oracle-instantclient-odbc.rpm https://download.oracle.com/otn_software/linux/instantclient/2340000/oracle-instantclient-odbc-23.4.0.24.05-1.el9.x86_64.rpm
RUN alien -i --scripts oracle-instantclient-odbc.rpm

RUN /usr/lib/oracle/23/client64/bin/odbc_update_ini.sh "/" "/usr/lib/oracle/23/client64/lib" "Oracle"

#RUN /etc/init.d/apache2 restart