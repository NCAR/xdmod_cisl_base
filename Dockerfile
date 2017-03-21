FROM cisl-repo/xdmod_distro:1.0

ENV REFRESHED_AT 2017-03-20
LABEL repo=cisl-repo \
      name=xdmod_cisl_base \
      version=1.0

ENV VOL_SECRETS=/run/secrets \
    VOL_LOGS=/var/log \
    VOL_APP_DATA=/var/xdmod \
    VOL_DB_DATA=/var/lib/mysql \
    HOME=/home/xdmod \
    PATH=${PATH}:/home/xdmod/bin

RUN yum -y install \
    mailx \
    python-yaml

RUN git clone https://github.com/NCAR/sweg-docker-util /sweg-docker-util

COPY etc /etc

WORKDIR /
RUN patch -p1 </etc/patch/5.6-001.patch ; \
    patch -p1 </etc/patch/5.6-002.patch ; \
    patch -p1 </etc/patch/5.6-003.patch

# Setup xdmod user
RUN useradd -d ${HOME} -m -s /bin/bash -U xdmod
WORKDIR ${HOME}
RUN mkdir bin ; ln -s /bin/xdmod-* bin

#
# Secrets ($VOL_SECRETS)
#
# mysql-xdmod.ini should be in the format of a .ini file, with the same
# sections portal_settings.ini uses for database configuration ([logger],
# [database], [datawarehouse], [shredder], [hpcdb]). The only parameters set
# should be "pass = <passwd>" parameters.
#
# ~xdmod/.ssh keys are used by scripts that fetch accounting log files
# 
RUN ln -s $VOL_SECRETS/mysql-xdmod.ini /etc/xdmod/portal_settings.d/secrets.ini ; \
    mkdir /home/xdmod/.ssh ; \
    chown xdmod /home/xdmod/.ssh ; \
    ln -s $VOL_SECRETS/xdmod-id_rsa /home/xdmod/.ssh/id_rsa ; \
    ln -s $VOL_SECRETS/xdmod-id_rsa.pub /home/xdmod/.ssh/id_rsa.pub

#
# Note that the list of files to be patched by deploy-env.sh is in
# /etc/deploy-env.conf. If you want to build a new image from this container
# that has additional files to patch, append the list of additional files to
# /etc/deploy-env.conf
#
ONBUILD ENTRYPOINT [ \
    "/sweg-docker-util/deploy-env.sh", \
    "-vvv" \
]
ENTRYPOINT [ \
    "/sweg-docker-util/deploy-env.sh", \
    "-vvv" \
]

VOLUME [ \
  "${VOL_SECRETS}", \
  "${VOL_LOGS}", \
  "${VOL_APP_DATA}" \
  "${VOL_DB_DATA}" \
]

CMD [ "runuser", "-m", "-u", "xdmod", "/bin/bash" ]
