FROM alpine:3.10
RUN apk add --no-cache bash nodejs npm
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]