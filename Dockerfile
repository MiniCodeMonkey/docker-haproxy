FROM centos:centos7

ENV   HAPROXY_MJR_VERSION=2.2 \
      HAPROXY_VERSION=2.2.4 \
      HAPROXY_CONFIG='/etc/haproxy/haproxy.cfg' \
      HAPROXY_ADDITIONAL_CONFIG='' \
      HAPROXY_PRE_RESTART_CMD='' \
      HAPROXY_POST_RESTART_CMD='' \
      OPENSSL_VERSION=1.1.1h

RUN \
  yum install -y epel-release && \
  yum update -y && \
  `# Install build tools. Note: perl needed to compile openssl...` \
  yum install -y \
  inotify-tools \
  wget \
  tar \
  gzip \
  make \
  gcc \
  perl \
  pcre-devel \
  zlib-devel \
  iptables \
  pth-devel

# Install openssl...
RUN \
  wget -O /tmp/openssl.tgz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
  tar -zxf /tmp/openssl.tgz -C /tmp && \
  cd /tmp/openssl-* && \
  ./config --prefix=/usr/local/openssl \
  --openssldir=/usr/local/openssl \
  --libdir=lib          \
  no-shared zlib-dynamic && \
  make -j$(getconf _NPROCESSORS_ONLN) V= && make install_sw && \
  cd && rm -rf /tmp/openssl*

# Install HAProxy...
RUN \
  wget -O /tmp/haproxy.tgz http://www.haproxy.org/download/${HAPROXY_MJR_VERSION}/src/haproxy-${HAPROXY_VERSION}.tar.gz && \
  tar -zxvf /tmp/haproxy.tgz -C /tmp && \
  cd /tmp/haproxy-* && \
  make \
  -j$(getconf _NPROCESSORS_ONLN) V= \
  TARGET=linux-glibc \
  USE_LINUX_TPROXY=1 \
  USE_ZLIB=1 \
  USE_REGPARM=1 \
  USE_PCRE=1 \
  USE_PCRE_JIT=1 \
  USE_OPENSSL=1 \
  SSL_INC=/usr/local/openssl/include \
  SSL_LIB=/usr/local/openssl/lib \
  ADDLIB=-ldl \
  ADDLIB=-lpthread \
  CFLAGS="-O2 -g -fno-strict-aliasing -DTCP_USER_TIMEOUT=18" && \
  make install && \
  rm -rf /tmp/haproxy* && \
  `# Configure HAProxy...` \
  mkdir -p /var/lib/haproxy && \
  groupadd haproxy && adduser haproxy -g haproxy && chown -R haproxy:haproxy /var/lib/haproxy && \
  `# Clean up: build tools...` \
  yum remove -y make gcc pcre-devel && \
  yum clean all && rm -rf /var/cache/yum

COPY container-files /

ENTRYPOINT ["/bootstrap.sh"]
