# This image provides a base for building and running Java applications.
# It builds using maven and runs the resulting artifacts

FROM openshift/base-centos7

MAINTAINER Askannon <askannon@flexarc.com>

EXPOSE 8778

ENV MAVEN_VERSION 3.3.3
ENV JAVA_AGENT -javaagent:jolokia-agent.jar=host=0.0.0.0
ENV JVM_ARGS -Dlog4j.configuration=etc/log4j.properties
ENV JOLOKIA_VERSION 1.3.1

LABEL io.k8s.description="Platform for building and running Java 8 applications" \
      io.k8s.display-name="Java 8" \
      io.openshift.expose-services="8778:jolokia" \
      io.openshift.tags="builder,java,java8" \
      io.openshift.s2i.destination="/opt/s2i/destination"

# Install Maven
RUN yum install -y --enablerepo=centosplus \
    tar unzip bc which lsof java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    yum clean all -y && \
    (curl -0 http://www.us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn && \
	mkdir -p /java/lib && \
    mkdir -p /opt/s2i/destination

# Fetch the Jolokia agent
ADD http://central.maven.org/maven2/org/jolokia/jolokia-jvm/1.3.1/jolokia-jvm-$JOLOKIA_VERSION-agent.jar /java/jolokia-agent.jar
	
# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

RUN chmod -R g+rw /opt/s2i/destination

USER 1001

CMD $STI_SCRIPTS_PATH/usage