FROM google/dart:latest

WORKDIR /app

RUN apt-get update && apt-get install -y fish

ADD pubspec.* /app/
RUN pub get
ADD . /app/
RUN pub get --offline
