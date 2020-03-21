# builder
from alpine:3.11.3 as builder

run apk --no-cache add git go

run mkdir /bors
copy bors.go go.mod /bors/
workdir /bors
RUN go build

# final stage
from alpine:3.11.3 as final

run mkdir /bors

copy contrib/* /bors/

copy --from=builder /bors/bors /bors/

workdir /bors/
entrypoint ["/bors/bors", "-f", "routes.yml"]
