FROM ubuntu:latest AS builder
RUN apt update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
RUN apt install -y build-essential gcc g++ automake git-core autoconf make patch libmysql++-dev libtool libssl-dev grep binutils zlibc libc6 libbz2-dev cmake subversion libboost-all-dev git mariadb-server

WORKDIR /cmangos
RUN mkdir build run
RUN git clone https://github.com/cmangos/mangos-classic.git mangos
RUN git clone https://github.com/cmangos/classic-db.git

WORKDIR /cmangos/build
RUN cmake -DDEBUG=0 -DBUILD_EXTRACTORS=ON -DBUILD_PLAYERBOT=ON -DBUILD_AHBOT=ON -DCMAKE_INSTALL_PREFIX=../run ../mangos
RUN make -j`nproc`
RUN make install

WORKDIR /cmangos
COPY wow tmp
RUN mv run/bin/tools/* tmp
RUN rmdir run/bin/tools

WORKDIR /cmangos/tmp
RUN printf "8\ny\ny" | bash ExtractResources.sh a
RUN mv maps dbc Cameras vmaps mmaps ../run/bin

WORKDIR /cmangos
RUN service mysql start && \
    mysql < mangos/sql/create/db_create_mysql.sql && \
    mysql classicmangos < mangos/sql/base/mangos.sql && \
    mysql classiccharacters < mangos/sql/base/characters.sql && \
    mysql classicrealmd < mangos/sql/base/realmd.sql && \
    mysql classiclogs  < mangos/sql/base/logs.sql && \
    printf "FORCE_WAIT=NO\nCORE_PATH=../mangos" > classic-db/InstallFullDB.config && \
    sed -i 's/MYSQL_COMMAND=.*/MYSQL_COMMAND="mysql classicmangos"/g' classic-db/InstallFullDB.sh && \
    cd classic-db && bash InstallFullDB.sh

#move cfg
RUN mv run/etc/mangosd.conf.dist run/etc/mangosd.conf
RUN mv run/etc/realmd.conf.dist run/etc/realmd.conf
RUN mv run/etc/ahbot.conf.dist run/etc/ahbot.conf
RUN mv run/etc/playerbot.conf.dist run/etc/playerbot.conf
RUN mv run/etc/anticheat.conf.dist run/etc/anticheat.conf

FROM ubuntu:latest
COPY --from=builder /cmangos/run /cmangos
COPY --from=builder /var/lib/mysql /var/lib/mysql_bak
ENV MYSQL_ROOT_PASSWORD=SomeFknPassword
RUN apt-get update && apt-get install -y mariadb-server screen
RUN sed -i 's/bind-address/#bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
RUN if [ ! -d /var/lib/mysql/classicmangos ]; then rm -rf /var/lib/mysql/* && mv /var/lib/mysql_bak/* /var/lib/mysql/; fi && \
    service mysql start && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'SomeFknPassword' WITH GRANT OPTION;"
WORKDIR /cmangos/bin
CMD service mysql start && \
    screen -dm bash -c "./mangosd" && \
    ./realmd