# Dockerfile to have a container with everything ready to build speculos,
# assuming that neither OpenSSL nor cmocka were updated.
#
# Support Debian buster & Ubuntu Bionic

FROM docker.io/library/python:3.9-slim
ENV LANG C.UTF-8

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -qy \
    cmake \
    curl \
    gcc-arm-linux-gnueabihf \
    git \
    libc6-dev-armhf-cross \
    libvncserver-dev \
    python3-pip \
    qemu-user-static \
    wget && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/

# There are issues with PYTHONHOME if using distro packages, use pip instead.
#RUN pip3 install construct flake8 flask flask_restful jsonschema mnemonic pycrypto pyelftools pbkdf2 pytest Pillow requests

# Create SHA256SUMS, download dependencies and verify their integrity
RUN \
  echo ee0078adcef1de5f003c62c80cc96527721609c6f3bb42b7795df31f8b558c0b openssl-3.0.3.tar.gz >> SHA256SUMS && \
  echo f0ccd8242d55e2fd74b16ba518359151f6f8383ff8aef4976e48393f77bba8b6 cmocka-1.1.5.tar.xz >> SHA256SUMS && \
  wget --quiet https://www.openssl.org/source/openssl-3.0.3.tar.gz && \
  wget --quiet https://cmocka.org/files/1.1/cmocka-1.1.5.tar.xz && \
  sha256sum --check SHA256SUMS && \
  rm SHA256SUMS


# Build dependencies and install them in /install
RUN mkdir install && \
  tar xf openssl-3.0.3.tar.gz && \
  cd openssl-3.0.3 && \
  ./Configure --cross-compile-prefix=arm-linux-gnueabihf- no-asm no-threads no-shared no-sock linux-armv4 --prefix=/install && \
  make -j CFLAGS=-mthumb && \
  make install_sw && \
  cd .. && \
  rm -r openssl-3.0.3/ openssl-3.0.3.tar.gz

RUN mkdir cmocka && \
  tar xf cmocka-1.1.5.tar.xz && \
  cd cmocka && \
  cmake ../cmocka-1.1.5 -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_C_FLAGS=-mthumb -DWITH_STATIC_LIB=true -DCMAKE_INSTALL_PREFIX=/install && \
  make install && \
  cd .. && \
  rm -r cmocka/ cmocka-1.1.5/ cmocka-1.1.5.tar.xz

CMD ["/bin/bash"]
