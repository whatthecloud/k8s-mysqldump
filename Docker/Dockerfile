FROM alpine:latest

RUN apk add --no-cache mysql-client bash openssl openssh-client

COPY dump.sh /usr/local/bin/dump
COPY import.sh /usr/local/bin/import

VOLUME ["/dump"]

CMD ["/usr/local/bin/dump"]

