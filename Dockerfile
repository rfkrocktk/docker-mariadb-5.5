FROM phusion/baseimage:0.9.10
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

# Ensure everything is UTF-8, because there's no reason in the world why not.
ENV LANG en_US.UTF-8
#ENV LC_ALL en_US.UTF-8 # gives a warning to stderr :( 
RUN locale-gen en_US.UTF-8

# Install MariaDB PPA
ADD conf/apt/mariadb.list /etc/apt/sources.list.d/mariadb.list
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
     && apt-get update -q 2 \
     && DEBIAN_FRONTEND=noninteractive apt-get install --yes -q 2 mariadb-server pwgen \
            inotify-tools

RUN mv /var/lib/mysql /data
RUN mv /var/log/mysql /log
RUN mv /etc/mysql /config

# Configure MariaDB to bind to 0.0.0.0, as is required for Docker containers
RUN sed -i 's:^bind-address\s*=\s127\.0\.0\.1:bind-address = 0.0.0.0:g' /config/my.cnf

# Configure MariaDB to log to /log
RUN sed -i 's:/var/log/mysql:/log:g' /etc/mysql/my.cnf

# Configure MariaDB to store data in /data
RUN sed -i 's:/var/lib/mysql:/data:g' /etc/mysql/my.cnf

# Run Initial Setup
ADD scripts/mariadb-first-run.sh /sbin/mariadb-first-run
ADD scripts/mariadb.sh /etc/service/mariadb/run/

RUN chmod +x /sbin/mariadb-first-run

# Mount Shared Volumes
VOLUME ["/config", "/data", "/log"]

# Expose TCP Port 3306
EXPOSE 3306

# Set Main Command
CMD ["/sbin/my_init"]

# Generate SSH host keys so that we can connect if desired
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Cleanup apt now that building is done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
