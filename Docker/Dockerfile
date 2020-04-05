FROM alpine:3.4
RUN apk add --update mysql-client bash openssl openssh-client && rm -rf /var/cache/apk/*
COPY dump.sh /
COPY import.sh /
ENTRYPOINT ["/dump.sh"]
