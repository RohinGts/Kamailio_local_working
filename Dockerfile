FROM ubuntu:16.04
RUN apt-get update
RUN apt-get install wget -y

RUN wget http://deb.kamailio.org/kamailiodebkey.gpg
RUN echo "deb http://deb.kamailio.org/kamailio41 precise main" >> /etc/apt/sources.list

RUN apt-get install mysql-shell -y
RUN apt-get install kamailio kamailio-mysql-modules kamailio-nth kamailio-utils-modules rtpproxy -y

WORKDIR /etc/kamailio/

RUN ipq=$(ifconfig docker0 | grep "inet " | awk -F'[: ]+' '{ print $4 }')
RUN echo 'SIP_DOMAIN='$ipq >> kamctlrc
RUN echo 'DBENGINE=MYSQL' >> kamctlrc
RUN echo 'DBHOST=localhost' >> kamctlrc
RUN echo 'DBNAME=kamailio' >> kamctlrc
RUN echo 'DBRWUSER="kamailio"' >> kamctlrc
RUN echo 'DBRWPW="ifpb"' >> kamctlrc
RUN echo 'ALIASES_TYPE="DB"' >> kamctlrc
RUN echo 'CTLENGINE="FIFO"' >> kamctlrc
RUN echo 'FIFOPATH="/var/run/kamailio/kamailio_fifo"' >> kamctlrc
RUN echo 'VERBOSE=1' >> kamctlrc

RUN echo '#!define WITH_MYSQL' >> kamailio.cfg
RUN echo '#!define WITH_ALIASDB' >> kamailio.cfg
RUN echo '#!define WITH_AUTH' >> kamailio.cfg
RUN echo '#!define WITH_USRLOCDB' >> kamailio.cfg
RUN echo '#!define WITH_IPAUTH' >> kamailio.cfg

WORKDIR /etc/defaults/
RUN ipl=$(echo '"-l ' ${ipq}'"')
RUN sed -i 's|""|'"$ipl"'|g' rtpproxy

RUN kamdbctl create
RUN kamctl add userx ifpb
RUN kamctl add usery ifpb
RUN kamctl alias_db add alexandra@$ipq userx@$ipq
RUN kamctl alias_db add rohin@$ipq usery@$ipq

RUN /etc/init.d/rtpproxy restart

RUN /etc/init.d/kamailio restart
