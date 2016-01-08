FROM alpine:3.3

MAINTAINER Askannon <askannon@flexarc.com>

EXPOSE 8778

ENV STI_SCRIPTS_PATH=/usr/libexec/s2i
ENV JOLOKIA_VERSION=1.3.1
ENV MAVEN_VERSION=3.3.3
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV JAVA_APP_DIR=/opt/app
ENV HOME=/opt/s2i/destination
ENV PATH=/opt/s2i/destination/bin:/opt/app/bin:$PATH

LABEL io.k8s.description="Platform for building and running Java 8 applications" \
      io.k8s.display-name="Java 8" \
      io.openshift.expose-services="8778/tcp:jolokia" \
      io.openshift.tags="builder,java,java8" \
      io.openshift.s2i.destination="/opt/s2i/destination" \
          io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

RUN mkdir -p ${HOME} && adduser -D -u 1001 -h ${HOME} -s /sbin/nologin \
      -g "Default Application User" default && \
  chown -R 1001:1001 ${HOME}

RUN mkdir -p $JAVA_APP_DIR && \
        mkdir -p $STI_SCRIPTS_PATH && \
        mkdir -p /opt/jolokia

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && apk add --update \
        bash \
  curl \
  openjdk8 \
  ngrep \
        tcpdump \
        lsof \
        tar \
        bc \
        unzip \
		ca-certificates && \
 rm /var/cache/apk/*

# Update keystore since apline doesn't causing SSL issues
RUN find /usr/share/ca-certificates/mozilla/ -name "*.crt" -exec keytool -import -trustcacerts \
	-keystore ${JAVA_HOME}/jre/lib/security/cacerts -storepass changeit -noprompt \
	-file {} -alias {} \; && \
	keytool -list -keystore ${JAVA_HOME}/jre/lib/security/cacerts --storepass changeit
 
# Install Maven
RUN (curl -0 http://www.us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn

# Fetch the Jolokia agent
ADD http://central.maven.org/maven2/org/jolokia/jolokia-jvm/$JOLOKIA_VERSION/jolokia-jvm-$JOLOKIA_VERSION-agent.jar /opt/jolokia/jolokia-agent.jar

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

RUN chown -R 1001:1001 $JAVA_APP_DIR && \
        chmod -R ug+rw $JAVA_APP_DIR && \
        chmod -R +x $STI_SCRIPTS_PATH/*

USER 1001

CMD $STI_SCRIPTS_PATH/usage
