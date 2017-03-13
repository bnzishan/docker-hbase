#FROM alpine:3.4
FROM bde2020/hadoop-base:1.1.0-hadoop2.7.1-java8
MAINTAINER smizy

LABEL \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="smizy/hbase" \
    org.label-schema.url="https://github.com/smizy" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/smizy/hbase"

ENV HBASE_VERSION    1.3.0
ENV HBASE_HOME       /usr/local/hbase-${HBASE_VERSION}
ENV HADOOP_VERSION   2.7.1
ENV HADOOP_HOME      /opt/hadoop/hadoop-${HADOOP_VERSION}
ENV HBASE_CONF_DIR   ${HBASE_HOME}/conf
ENV HBASE_LOG_DIR    /var/log/hbase
ENV HBASE_TMP_DIR    /hbase

ENV JAVA_HOME  /usr/lib/jvm/default-jvm
ENV PATH       $PATH:${JAVA_HOME}/bin:${HBASE_HOME}/sbin:${HBASE_HOME}/bin:${HADOOP_HOME}/bin

ENV HADOOP_NAMENODE1_HOSTNAME     namenode-1.vnet
ENV HBASE_ROOT_DIR                hdfs://${HADOOP_NAMENODE1_HOSTNAME}:8020/hbase
ENV HBASE_HMASTER1_HOSTNAME       hmaster-1.vnet
ENV HBASE_REGIONSERVER1_HOSTNAME  regionserver-1.vnet
ENV HBASE_ZOOKEEPER_QUORUM        zookeeper-1.vnet,zookeeper-2.vnet,zookeeper-3.vnet


RUN ln -s /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/default-jvm
RUN apt-get install -y netcat
RUN apt-get install -y wget 

RUN mirror_url=$( \
        wget -q -O - http://www.apache.org/dyn/closer.cgi/hbase/ \
        | sed -n 's#.*href="\(http://ftp.[^"]*\)".*#\1#p' \
        | head -n 1 \
    ) \   
    && wget -q -O - ${mirror_url}/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
        | tar -xzf - -C /usr/local
RUN useradd -r -u 1000 docker
RUN for user in hadoop hbase; do \
         useradd -r ${user}; \
       done
RUN for user in root hbase docker; do \
         usermod -aG hadoop ${user}; \
       done        
RUN mkdir -p \
        ${HBASE_TMP_DIR} \
        ${HBASE_LOG_DIR}
RUN chmod -R 755 \
        ${HBASE_TMP_DIR} \
        ${HBASE_LOG_DIR}
RUN chown -R hbase:hadoop \
        ${HBASE_TMP_DIR} \
        ${HBASE_LOG_DIR} 
RUN rm -rf ${HBASE_HOME}/docs
RUN sed -i.bk -e 's/PermSize/MetaspaceSize/g' ${HBASE_CONF_DIR}/hbase-env.sh  


COPY etc/*  ${HBASE_CONF_DIR}/    
COPY bin/*  /usr/local/bin/ 
COPY lib/*  /usr/local/lib/
    
WORKDIR ${HBASE_HOME}

VOLUME ["${HBASE_TMP_DIR}", "${HBASE_LOG_DIR}", "${HBASE_HOME}"]

ENTRYPOINT ["entrypoint.sh"]
