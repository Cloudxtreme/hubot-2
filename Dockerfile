FROM node 

MAINTAINER "Piotr Zduniak <piotr@zduniak.net>"

ADD . /hubot
RUN cd /hubot && npm install

EXPOSE 8080

CMD cd /hubot && bin/hubot --adapter slack
