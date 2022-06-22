FROM amazoncorretto:11
COPY target/myspringmetricsplanet-0.0.1-SNAPSHOT.jar myspringmetricsplanet-0.0.1-SNAPSHOT.jar
RUN mkdir heapdump 
ENTRYPOINT ["java", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:HeapDumpPath=/heapdump/oom-$(date +'%d-%m-%Y-%H-%M').bin", "-jar", "./myspringmetricsplanet-0.0.1-SNAPSHOT.jar"]


