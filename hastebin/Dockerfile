FROM node
MAINTAINER Vaclav Adamec <vaclav.adamec@suchy-zleb.cz>

ADD tests/ /opt/tests/
ADD run.sh /opt/
ADD haste-client /usr/local/bin/haste

RUN git clone https://github.com/seejohnrun/haste-server.git /opt/hastebin \
    && apt-get update \
    && apt-get install ruby rake python-pip netcat -y \
    && gem install serverspec yarjuf \
    && pip install requests \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/hastebin
RUN npm install
ADD config.js /opt/hastebin/config.js

EXPOSE 8080
CMD ["npm", "start"]
