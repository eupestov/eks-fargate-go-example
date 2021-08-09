FROM golang:1.16-alpine as builder

WORKDIR /app

COPY app .
RUN go mod download

RUN go build -o service

FROM golang:1.16-alpine

LABEL maintainer="eugene.pestov@gmail.com"

ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_VERSION
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG BUNDLER_VERSION=1.16.0

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="eupestov/devops" \
      org.label-schema.description="TMNL's Cloud Engineer challenge" \
      org.label-schema.vcs-url="https://github.com/eupestov/devops_challenge" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.version=${BUILD_VERSION} \
      org.label-schema.docker.cmd="docker run -p 8080:8080 -d eupestov/devops"

WORKDIR /app

COPY --from=builder /app/service /app/service

RUN addgroup --gid ${GROUP_ID} user && \
    adduser -D -g '' -u ${USER_ID} -G user user && \
    chown -R user:user /app

USER ${USER_ID}

EXPOSE 8080

ENTRYPOINT ["/app/service"]