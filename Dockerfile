FROM cisl-repo/xdmod_distro:1.4

ENV REFRESHED_AT 2018-12-21
LABEL repo=cisl-repo \
      name=xdmod_cisl_base \
      version=1.8

ARG HOME=/home/xdmod
ARG TZ=America/Denver

ENV APP_NAME=xdmod_cisl \
    VOL_SECRETS=/run/secrets \
    VOL_LOGS=/var/log \
    VOL_DB_DATA=/var/lib/mysql \
    HOME=$HOME \
    TZ=$TZ \
    PATH=${PATH}:$HOME/bin

RUN yum -y install \
    mailx \
    ssmtp

RUN git clone https://github.com/NCAR/sweg-docker-util /sweg-docker-util

COPY etc /etc

WORKDIR /
RUN patch -p1 </etc/patch/6.6-001.patch ; \
    patch -p1 </etc/patch/6.6-002.patch ; \
    patch -p1 </etc/patch/6.6-003.patch

RUN rm -f /etc/alternatives/mta ; \
    ln -s /usr/sbin/ssmtp /etc/alternatives/mta

# Setup xdmod user
RUN useradd -d $HOME -m -s /bin/bash -U xdmod
WORKDIR $HOME
RUN mkdir bin ; ln -s /bin/xdmod-* bin

# add apache to xdmod group for secrets.ini symlink
RUN usermod -a -G xdmod apache

# set timezone...
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/$TZ /etc/localtime

#
# mysql-root-password should contain the root MySQL paswords.
# mysql-xdmod.ini should contain a "[secrets]" section in which there is a
# key of the form "xdmod@<dbhost>", the value of which is the xdmod password.
# 
RUN ln -s /run/secrets/mysql-xdmod.ini /etc/xdmod/portal_settings.d/secrets.ini

#
# Note that the list of files to be patched by deploy-env.sh is in
# /etc/deploy-env-files.cnf. If you want to build a new image from this
# container that has additional files to patch, append the list of additional
# files to /etc/deploy-env-files.cnf
#
ONBUILD ENTRYPOINT [ \
    "/sweg-docker-util/deploy-env.sh", \
    "-vvv" \
]
ENTRYPOINT [ \
    "/sweg-docker-util/deploy-env.sh", \
    "-vvv" \
]

VOLUME \
    ${VOL_SECRETS} \
    ${VOL_LOGS} \
    ${VOL_DB_DATA}

CMD [ "runuser", "-m", "-u", "xdmod", "/bin/bash" ]
