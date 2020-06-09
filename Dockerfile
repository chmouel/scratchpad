FROM golang AS builder

COPY . /go/src/httpserver
WORKDIR /go/src/httpserver

RUN  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-w'  -o httpserver

FROM scratch

COPY --from=builder /go/src/httpserver/httpserver /go/bin/httpserver

ENTRYPOINT ["/go/bin/httpserver"]

EXPOSE 8080
