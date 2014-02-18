FROM ubuntu
 
RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates universe' >> /etc/apt/sources.list && \
    apt-get update

#Prevent daemon start during install
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -s /bin/true /sbin/initctl

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir /var/run/sshd && \
	echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat

#Hack to avoid install problem
RUN mkdir /etc/foundationdb && touch /etc/foundationdb/fdb.cluster

#FoundationDB Client, must install before server
RUN wget https://foundationdb.com/downloads/I_accept_the_FoundationDB_Community_License_Agreement/2.0.1/foundationdb-clients_2.0.1-1_amd64.deb && \
    dpkg -i foundationdb-clients_2.0.1-1_amd64.deb && \
    rm foundationdb-clients_*.deb

#FoundationDB Server 
RUN wget https://foundationdb.com/downloads/I_accept_the_FoundationDB_Community_License_Agreement/2.0.1/foundationdb-server_2.0.1-1_amd64.deb && \
    dpkg -i foundationdb-server_2.0.1-1_amd64.deb && \
    rm foundationdb-server_*.deb 

#Setup proper ownership and permissions 
RUN chown -f foundationdb:foundationdb /etc/foundationdb/fdb.cluster && \
    chmod -f 0644 /etc/foundationdb/fdb.cluster

#Run this sequence to create the initial database
#/etc/init.d/foundationdb start && \
#/usr/bin/fdbcli -C /etc/foundationdb/fdb.cluster --exec "configure new single memory; status" --timeout 20 && \
#/etc/init.d/foundationdb stop

ADD supervisord-ssh.conf /etc/supervisor/conf.d/supervisord-ssh.conf
ADD supervisord-foundationdb.conf /etc/supervisor/conf.d/

EXPOSE 22
RUN rm -rf /tmp/*
