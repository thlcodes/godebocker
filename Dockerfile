FROM golang:1.13-alpine AS builder

RUN apk update && apk add --no-cache git openssh gcc

RUN go get -u github.com/go-delve/delve/cmd/dlv

ENV PORT 8080
ENV DLVPORT 4040
ENV GOPRIVATE ""
ENV CGO_ENABLED 0
ENV BUILD false
ENV BINARY "./bin"
ENV SSH_KEY ""
ENV ARGS ""
ENV KNOWN_HOSTS ""
ENV WORKDIR "/app"
ENV CONTINUE true
ENV BEGIN_MSG "godebocker started"
ENV DLV_LOG false

EXPOSE ${PORT} ${DLVPORT}

WORKDIR /app

COPY godebugger.sh /usr/local/bin/godebugger

RUN which godebugger

CMD ["sh", "-c", "godebugger"]