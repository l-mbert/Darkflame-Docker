# syntax=docker/dockerfile:1
# Download base image ubuntu 20.04
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
# CURRENTLY NOT USED
ARG EXTERNAL_IP=localhost

# Install needed Packages
RUN apt update
RUN apt-get -y install sudo software-properties-common
RUN sudo add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get -y install gcc mono-mcs build-essential g++ cmake zlib1g-dev mariadb-server sqlite3 python3.7 python3-pip unzip git vim \
    && rm -rf /var/lib/apt/lists/*

# Set C++ Compiler Paths
RUN export CC=/usr/bin/gcc && export CXX=/usr/bin/g++

# Install Bitstream Utilitiy
RUN pip3 install git+https://github.com/lcdr/bitstream.git

# Clone DarkflameServer Repo
RUN git clone --recursive https://github.com/DarkflameUniverse/DarkflameServer.git /DarkflameServer
# Clone utils Repo
RUN git clone https://github.com/lcdr/utils /utils

WORKDIR /DarkflameServer

# Setup MySQL
RUN sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/mariadb.conf.d/50-server.cnf
RUN echo "mysqld_safe &" > /tmp/config
RUN echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config
RUN echo "mysql -e 'CREATE USER \"dlu\"@\"%\" IDENTIFIED BY \"Password1234\"; GRANT ALL PRIVILEGES ON *.* TO \"dlu\"@\"%\" WITH GRANT OPTION; FLUSH PRIVILEGES;'" >> /tmp/config
RUN echo "mysql -e 'CREATE DATABASE dlu; use dlu; SOURCE ./migrations/dlu/0_initial.sql;'" >> /tmp/config
RUN bash /tmp/config && \
  rm -f /tmp/config

# Set Cores to the Docker allocated ones
RUN sed -i -e "s/make$/make -j$(nproc)/g" ./build.sh

# Run DarkflameServers' own build-Script
RUN chmod +x ./build.sh
RUN ./build.sh

# PREVIOUSLY: Set IP to the given one by ARG
# RUN ex -s -c '%s/external_ip=localhost/external_ip='"$EXTERNAL_IP"'/g|x' ./build/masterconfig.ini
# RUN ex -s -c '%s/external_ip=localhost/external_ip='"$EXTERNAL_IP"'/g|x' ./build/authconfig.ini
# RUN ex -s -c '%s/external_ip=localhost/external_ip='"$EXTERNAL_IP"'/g|x' ./build/chatconfig.ini

# Update IP to be Dockers internal IP (sometimes the Server will just crash because it can't listen to the IP or whatever)
COPY update_ip.sh /update_ip.sh
RUN chmod +x /update_ip.sh
RUN /update_ip.sh

# Create needed logs-Folder
RUN mkdir -p /DarkflameServer/build/logs

# Copy over Client Files
RUN mkdir -p /DarkflameServer/build/res
COPY /Client/res/maps /DarkflameServer/build/res/maps
COPY /Client/res/macros /DarkflameServer/build/res/macros
COPY /Client/res/chatplus_en_us.txt /DarkflameServer/build/res
COPY /Client/res/BrickModels /DarkflameServer/build/res/BrickModels

RUN mkdir -p /DarkflameServer/build/locale
COPY /Client/locale/locale.xml /DarkflameServer/build/locale

RUN unzip ./resources/navmeshes.zip -d ./build/res/maps

# Setup SQLite Database and run migrations on it
COPY /Client/res/cdclient.fdb /DarkflameServer/build/cdclient.fdb
RUN python3 /utils/utils/fdb_to_sqlite.py /DarkflameServer/build/cdclient.fdb
RUN mv /DarkflameServer/cdclient.sqlite /DarkflameServer/build/res/CDServer.sqlite
RUN sqlite3 -init "./migrations/cdserver/0_nt_footrace.sql" ./build/res/CDServer.sqlite .quit
RUN sqlite3 -init "./migrations/cdserver/1_fix_overbuild_mission.sql" ./build/res/CDServer.sqlite .quit
RUN sqlite3 -init "./migrations/cdserver/2_script_component.sql" ./build/res/CDServer.sqlite .quit

# Update mysql-Credentials on all Databases
RUN ex -s -c '%s/mysql_host=/mysql_host=127.0.0.1/g|x' ./build/authconfig.ini
RUN ex -s -c '%s/mysql_database=/mysql_database=dlu/g|x' ./build/authconfig.ini
RUN ex -s -c '%s/mysql_username=/mysql_username=dlu/g|x' ./build/authconfig.ini
RUN ex -s -c '%s/mysql_password=/mysql_password=Password1234/g|x' ./build/authconfig.ini

RUN ex -s -c '%s/mysql_host=/mysql_host=127.0.0.1/g|x' ./build/chatconfig.ini
RUN ex -s -c '%s/mysql_database=/mysql_database=dlu/g|x' ./build/chatconfig.ini
RUN ex -s -c '%s/mysql_username=/mysql_username=dlu/g|x' ./build/chatconfig.ini
RUN ex -s -c '%s/mysql_password=/mysql_password=Password1234/g|x' ./build/chatconfig.ini

RUN ex -s -c '%s/mysql_host=/mysql_host=127.0.0.1/g|x' ./build/masterconfig.ini
RUN ex -s -c '%s/mysql_database=/mysql_database=dlu/g|x' ./build/masterconfig.ini
RUN ex -s -c '%s/mysql_username=/mysql_username=dlu/g|x' ./build/masterconfig.ini
RUN ex -s -c '%s/mysql_password=/mysql_password=Password1234/g|x' ./build/masterconfig.ini

RUN ex -s -c '%s/mysql_host=/mysql_host=127.0.0.1/g|x' ./build/worldconfig.ini
RUN ex -s -c '%s/mysql_database=/mysql_database=dlu/g|x' ./build/worldconfig.ini
RUN ex -s -c '%s/mysql_username=/mysql_username=dlu/g|x' ./build/worldconfig.ini
RUN ex -s -c '%s/mysql_password=/mysql_password=Password1234/g|x' ./build/worldconfig.ini

# Expose Ports
EXPOSE 3306
EXPOSE 1000-1050
EXPOSE 2000-2050
EXPOSE 3000-3050

# Get Entrypoint and set it
COPY entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]