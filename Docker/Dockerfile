FROM alpine:latest

RUN apk add --update mysql-client bash openssl openssh-client && rm -rf /var/cache/apk/*

COPY dump.sh /usr/local/bin/dump
COPY import.sh /usr/local/bin/import

VOLUME ["/dump"]

CMD ["/usr/local/bin/dump"]

