FROM ubuntu:14.04

MAINTAINER Decheng Zhang <killercentury@gmail.com>, Elvis de Freitas <edigitalb@gmail.com>

ENV JENKINS_PATH=/opt/jenkins
ENV JENKINS_VERSION=2.7.4
ENV DOCKER_COMPOSE_VERSION=1.8.1
ENV DOCKER_VERSION=1.12.1
ENV JENKINS_HOME=/var/lib/jenkins

RUN export TMP_DIR=`mktemp`

# Let's start with some basic stuff.
RUN apt-get update -qq && apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    lxc \
    iptables \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Docker from Docker Inc. repositories.
RUN curl -L https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION.tgz > $TMP_DIR/docker.tgz && \
	tar -xf $TMP_DIR/docker.tgz --strip 1 -C /usr/local/bin

# Install the wrapper script from https://raw.githubusercontent.com/docker/docker/master/hack/dind.
ADD ./dind /usr/local/bin/dind
RUN chmod +x /usr/local/bin/dind

ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Define additional metadata for our image.
VOLUME /var/lib/docker

# Install Jenkins
RUN mkdir $JENKINS_PATH && \
	curl -L http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war > $JENKINS_PATH/jenkins.war

# Install Docker Compose
RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose && rm -rf $TMP_DIR/*

EXPOSE 8080

RUN groupadd -r jenkins \
  && useradd -r -g jenkins jenkins && passwd -d jenkins && usermod -a -G docker jenkins && su jenkins

ENV HOME="/var/lib/jenkins"
ENV USER="jenkins"

CMD ["dind wrapdocker", "chown -R jenkins:jenkins /var/lib/jenkins && java -jar /usr/share/jenkins/jenkins.war"]