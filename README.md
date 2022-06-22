### TakingSpringBoot application Heap and Thread dump

In this tutorial, we will explore ways to capture Heap and Thread dump from a spring boot application running inside the Kubernetes cluster.

A Heap Dump is a snapshot of all the objects that are in memory in the JVM at a certain moment. They are very useful to troubleshoot memory-leak problems and optimize memory usage in Java applications.

A Thread Dump is a snapshot of the state of all the threads of a Java process. The state of each thread is presented with a stack trace, showing the content of a thread's stack. A thread dump is useful for diagnosing problems, as it displays the thread's activity.
## Actuator
In this tutorial, we are going to use an actuator, It is used to expose operational information about the running spring boot application, It exposes information like — health, metrics, info, dump, env, etc. It uses HTTP endpoints or JMX beans to enable us to interact.

To enable the spring boot actuator, we need to add the spring-boot-actuator dependency to the package manager (pom.xml). 

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>


The spring boot actuator’s thread dump actuator endpoint is enabled by default. The /threaddump endpoint isn’t exposed. The following configuration should be used to expose the /threaddump URL. All or a subset of endpoints can be exposed using a spring boot actuator. In a production environment, it is recommended to only expose the thread dump endpoint for security reasons. Otherwise, all of the actuator endpoints can be exposed.

Go to application.properties file and make changes to the file as shown below:-

management.endpoints.web.exposure.include=threaddump,heapdump


It will expose the thread dump and heap dump on the application URL like this http://URL:PORT/actuator/threaddump or  http://URL:PORT/actuator/heapdump  where the URL is your application URL or IP address and port number on which the application is exposed.
## Heap Dump

To retrieve the heap dump, make a GET request to /actuator/heapdump. The response is binary data in HPROF format and can be large. Typically, you should save the response to disk for subsequent analysis. When using curl, this can be achieved by using the -O option, as shown in the following example: 

curl 'http://localhost:8080/actuator/heapdump' -O


The preceding example results in a file named heapdump being written to the current working directory. 

We can also pass the -XX:+HeapDumpOnOutOfMemoryError parameter on application startup to get a heap dump when we get an out-of-memory error in our application. For this, you can run the below-mentioned command on docker start.

ENTRYPOINT ["java", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:HeapDumpPath=/heapdump/oom-$(date +'%d-%m-%Y-%H-%M').hprof", "-jar", "./myspringmetricsplanet-0.0.1-SNAPSHOT.jar"]


Here in above example we are passing “-XX:+HeapDumpOnOutOfMemoryError” this argument as entrypoint in Dockerfile. It will take a dump of the heap on the path defined in “-XX:HeapDumpPath”.

## Thread Dump
You can take thread dump from the container by using the command mentioned below:-

curl 'http://localhost:8080/actuator/threaddump' -i -X GET -H 'Accept: application/json' > "/var/log/jvm-thread-$(date +'%d-%m-%Y-%H-%M').log"


It will take a dump and it will store the thread dump at the location mentioned in the command with the time stamp.

## Deployment on Kubernetes
Now we need to do all the things in Kubernetes so, let us create a manifest file. We are going to use the sidecar approach.  Because If the OutOfMemory error is happening during start-up, you probably are not going to be able to copy the dump before the container is restarted. The issue happen so sporadically, that we could not just ssh to the application container and perform a jmap or jcmd. 

Before we had time, Kubernetes had already killed and restarted the container, which also meant that it had wiped out any heap dump that the JVM could have done with the -XX:+HeapDumpOnOutOfMemoryError flag.

In this case, we are going to add a sidecar to our pod and on that sidecar, we will mount the same empty dir, So we can access the heap dumps through the sidecar container, instead of the main container. 

And as we know if we are running a sidecar can container we can access the service running on the main container (Spring Boot Container) by using localhost.

Here we are using the fluent as a sidecar container so that if we want to copy the file from local to some cloud storage like AWS s3, GCP storage or Azure blob we can easily do that with a fluent application.

Heapdump will be taken by the container itself as we added the heapdump command on Dockerfile as an entrypoint and the Threaddump command is added on the fluent container as an argument in the manifest the command will get executed after every 1 minute in the loop. So, The threaddump is stored on the fluent container.

You can take a pull of the git repo then cd into the git directory where main.yaml file is and run command

kubectl apply -f main.yaml

To check the thread dump go inside the container by running below command

kubectl exec -it <pod-name> -c fluent


Once you are inside the container go to “/var/log” directory there you will find all the the threadump of the application. And in the “/heapdump” folder you will get the heapdump if your app has generated the heapdump.

If you want to send the thread dump or heap dump to remote storage you can configure the fluent configuration according to your requirements.
