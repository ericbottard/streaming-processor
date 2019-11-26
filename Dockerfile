FROM openjdk:8-jdk-alpine AS builder
WORKDIR target/dependency
ARG APPJAR=target/*.jar
COPY ${APPJAR} app.jar
RUN jar -xf ./app.jar

FROM oracle/graalvm-ce:19.2.0.1 AS native
RUN gu install native-image
ARG DEPENDENCY=target/dependency
COPY --from=builder ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=builder ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=builder ${DEPENDENCY}/BOOT-INF/classes /app
RUN native-image -Dio.netty.noUnsafe=true --no-server -H:Name=app/main -H:+ReportExceptionStackTraces --no-fallback --allow-incomplete-classpath --report-unsupported-elements-at-runtime -DremoveUnusedAutoconfig=true -cp app:`echo app/lib/*.jar | tr ' ' :` io.projectriff.processor.Processor

FROM ubuntu:bionic
COPY --from=native /app/main /app/main
ENTRYPOINT ["/app/main","${0}","${@}"]
