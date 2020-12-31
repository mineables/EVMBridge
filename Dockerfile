FROM ubuntu:18.04

COPY . /app
WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git npm curl

RUN npm install -g npm@latest
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN npm install
CMD npm start
# CMD /bin/bash