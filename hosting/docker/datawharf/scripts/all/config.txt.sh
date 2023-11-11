#!/bin/bash

##### Set up some variables that can be overridden in docker-compose file

# Intentionally the same environment variable names as the postgres docker image uses; if that's inconvenient, remap in the docker-compose file
POSTGRES_USER=${POSTGRES_USER:-datawharf}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-main}
POSTGRES_DB=${POSTGRES_DB:-DataWharfDemo}

# Other useful variables that could be set externally
POSTGRES_HOST=${POSTGRES_HOST:-host.docker.internal}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

##### Output config
cat <<EOC > /var/www/Harbour_websites/fcgi_DataWharf/backend/config.txt

ReloadConfigAtEveryRequest=true             //"true" or "false"
MaxRequestPerFCGIProcess=0                  //0 for Unlimited

POSTGRESDRIVER=PostgreSQL Unicode
POSTGRESHOST=${POSTGRES_HOST}
POSTGRESPORT=${POSTGRES_PORT}

//Database Login ID and Password
POSTGRESID=${POSTGRES_USER}
POSTGRESPASSWORD=${POSTGRES_PASSWORD}

//Name of Database. Initially if could be simply an empty database.
POSTGRESDATABASE=${POSTGRES_DB}

ShowDevelopmentInfo=No                      //No or Yes
APPLICATION_TITLE=DataWharf Demo
//COLOR_HEADER_BACKGROUND=E3F2FD
//COLOR_HEADER_TEXT_WHITE=No                //No or Yes
//LOGO_THEME_NAME=RainierSailBoat           //Images available from Repo: Earth_001, Blocks_001, Blocks_002, Blocks_003, RainierKayak, RainierSailBoat

SECURITY_DEFAULT_PASSWORD=password
SECURITY_SALT=0123456789ABCDEFG

CYANAUDIT_TRAC_USER=No                      //No or Yes

ODBC_DRIVER_POSTGRESQL=PostgreSQL Unicode
ODBC_DRIVER_MARIADB=MariaDB Unicode
ODBC_DRIVER_MYSQL=MySQL ODBC 8.0 Unicode Driver
ODBC_DRIVER_MSSQL=ODBC Driver 18 for SQL Server

EOC

ac_exe=`which apache2ctl`
if [ -z "$ac_exe" ]; then
	ac_exe=`which apachectl`
fi

$ac_exe start &

tail -f /var/www/Harbour_websites/fcgi_DataWharf/apache-logs/error.log
