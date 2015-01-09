FROM dockerfile/nodejs

MAINTAINER "Piotr Zduniak <piotr@zduniak.net>"

ADD . /hubot
RUN cd /hubot && npm install

EXPOSE 8080

CMD ["/hubot/bin/hubot --adapter slack"]
