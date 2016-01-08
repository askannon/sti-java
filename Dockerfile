FROM alpine:3.3

MAINTAINER Askannon <askannon@flexarc.com>

ENV STI_SCRIPTS_PATH="/usr/local/s2i" \
	JOLOKIA_VERSION="1.3.2" \
	MAVEN_VERSION="3.3.3" \
	JAVA_HOME="/usr/lib/jvm/default-jvm" \
	HAWTAPP_VERSION="2.2.53" \
	PATH=$PATH:"/usr/local/s2i" \
	AB_JOLOKIA_CONFIG="/opt/jolokia/jolokia.properties" \
	AB_JOLOKIA_AUTH_OPENSHIFT="true" \
	HOME="/deployments"

LABEL io.k8s.description="Platform for building and running plain Java 8 applications (flat classpath only)" \
		io.k8s.display-name="Java 8" \
		io.openshift.expose-services="8778/tcp:jolokia" \
		io.openshift.tags="builder,java,java8" \
		io.openshift.s2i.destination="/tmp" \
		io.openshift.s2i.scripts-url="image:///usr/local/s2i"

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

# Jolokia agent
ADD jolokia-opts /opt/jolokia/
ADD jolokia.properties /opt/jolokia/
ADD "http://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/${JOLOKIA_VERSION}/jolokia-jvm-${JOLOKIA_VERSION}-agent.jar /opt/jolokia/jolokia.jar"
RUN chmod 444 /opt/jolokia/jolokia.jar \
 && chmod 755 /opt/jolokia/jolokia-opts
EXPOSE 8778

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH
ADD README.md $STI_SCRIPTS_PATH/usage.txt

# Necessary to permit running with a randomised UID
RUN mkdir $HOME \
 && chmod -R "a+rwX" $HOME

# Add a user to run our stuff
RUN adduser -D -u 1001 -h ${HOME} -s /sbin/nologin -g "Default Application User" default

# S2I requires a numeric, non-0 UID
USER 1001

CMD $STI_SCRIPTS_PATH/usage
