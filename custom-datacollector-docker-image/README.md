# Custom StreamSets Data Collector Docker Image Example

This example shows how to build a custom StreamSets Data Collector Docker image pre-loaded with a set of Stage Libraries and other resources, suitable for Kubernetes-based deployment using [StreamSets Control Hub](https://streamsets.com/products/sch)


Consider a pipeline like this:

![Pipeline Example Image](images/pipeline-example.png)

In order for a Data Collector to run such a pipeline the following Stage Libraries (or related versions) must be included in the image

* streamsets-datacollector-apache-kafka_1_0-lib
* streamsets-datacollector-jdbc-lib
* streamsets-datacollector-elasticsearch_5-lib

as well as this JDBC Driver:

* mysql-connector-java-5.1.46.jar

Here are the steps to build such a Data Collector image with those dependencies: 

## Create a Dockerfile 
Create a Dockerfile with this content in a new directory I'll refer to as ```$PROJECT_HOME```.
Specify the version of SDC to use; in this example I'll use v3.2.0.0:

```dockerfile
ARG SDC_VERSION=3.2.0.0
FROM streamsets/datacollector:${SDC_VERSION}
ARG SDC_LIBS
RUN "${SDC_DIST}/bin/streamsets" stagelibs -install="${SDC_LIBS}"
COPY --chown=sdc:sdc resources/ ${SDC_RESOURCES}/
COPY --chown=sdc:sdc sdc-extras/ ${STREAMSETS_LIBRARIES_EXTRA_DIR}/
```
##  Add external libraries
To include external libraries in the image, like the JDBC driver mentioned above, add the file(s) to an ```sdc-extras``` directory at the root of the project, nested within the appropriate ```<stage-lib>/lib``` subdirectories, like this:

```
$PROJECT_HOME/sdc-extras/streamsets-datacollector-jdbc-lib/lib/mysql-connector-java-5.1.46.jar
````


##  Add external resources

Similarly, to include external resources, add them to a ```resources``` directory located here: 

```
$PROJECT_HOME/resources/
```

No external resources are needed for this example


## Build the image using the SDC_LIBS arg 
Switch to the root of the project and build the image using the ```SDC_LIBS``` arg to specify a comma-delimited set of stage libs to include, using a command like this:

```
$ docker build \
-t <your org name>/<your repo name> \
--build-arg SDC_LIBS=\
streamsets-datacollector-jdbc-lib,\
streamsets-datacollector-apache-kafka_1_0-lib,\
streamsets-datacollector-elasticsearch_5-lib \
.

```
Note the trailing ```.``` at the end of the command.

On my system, using my own org and repo name, I'll use the command:
```
$ docker build \
-t onefoursix/my_sdc \
--build-arg SDC_LIBS=\
streamsets-datacollector-jdbc-lib,\
streamsets-datacollector-apache-kafka_1_0-lib,\
streamsets-datacollector-elasticsearch_5-lib \
.
```

I can see my new image after the build completes:
```
$ docker images
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
onefoursix/my_sdc         latest              7acbcf095744        1 second ago        510MB
alpine                    3.6                 77144d8c6bdc        2 months ago        3.97MB
```


## Push the new image to your Docker Hub

Use a ```$ docker login``` command if you have not yet logged into your Docker Hub account.

Push your image to your Docker Hub account using a command of the form:

```
$  docker push <image name>
```

For example, on my system I will execute this command:

```
$  docker push onefoursix/my_sdc
```

Now that we have published a custom Data Collector image pre-built with the necessary stage and external libraries, we can deploy it using StreamSets Control Hub's Kubernetes-based deployment support.





