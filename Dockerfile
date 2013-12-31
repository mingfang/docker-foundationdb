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

#FoundationDB Server and Client
RUN wget https://foundationdb.com/downloads/I_accept_the_FoundationDB_Community_License_Agreement/1.0.1/foundationdb-server_1.0.1-1_amd64.deb && \
    wget https://foundationdb.com/downloads/I_accept_the_FoundationDB_Community_License_Agreement/1.0.1/foundationdb-clients_1.0.1-1_amd64.deb

#Hack to avoid install problem
RUN mkdir /etc/foundationdb && touch /etc/foundationdb/fdb.cluster
RUN dpkg -i foundationdb-clients_1.0.1-1_amd64.deb foundationdb-server_1.0.1-1_amd64.deb

RUN mktemp -u local:XXXXXXXX@127.0.0.1:4500 > /etc/foundationdb/fdb.cluster && \
    chown foundationdb:foundationdb /etc/foundationdb && \
    chown -f foundationdb:foundationdb /etc/foundationdb/fdb.cluster && \
    chmod -f 0644 /etc/foundationdb/fdb.cluster

#RUN /etc/init.d/foundationdb start && \
#    /usr/bin/fdbcli -C /etc/foundationdb/fdb.cluster --exec "configure new single memory; status" --timeout 20 && \
#    /etc/init.d/foundationdb stop

#Install layers
RUN git clone https://github.com/FoundationDB/python-layers.git

#IPython
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential python-dev python-pip
RUN pip install jinja2 pyzmq tornado
RUN pip install ipython
ENV IPYTHONDIR /ipython
RUN mkdir /ipython && \
    ipython profile create nbserver

ADD supervisord-ssh.conf /etc/supervisor/conf.d/supervisord-ssh.conf
ADD supervisord-ipython.conf /etc/supervisor/conf.d/
ADD supervisord-foundationdb.conf /etc/supervisor/conf.d/

#This will always run on each build to pull in latest
RUN cd /python-layers && \
    git pull

EXPOSE 22
RUN rm -rf /tmp/*