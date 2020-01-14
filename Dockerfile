# builder
from alpine:3.11.2 as builder

run apk add git go

run mkdir /bors
copy bors.go go.mod /bors/
workdir /bors
RUN go build

# final stage
from alpine:3.11.2 as final

copy bors.sh /

copy --from=builder /bors/bors /

entrypoint ["/bors", "-f", "bors.sh"]
