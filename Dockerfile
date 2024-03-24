FROM centos:8

# Update CentOS repositories to use vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Add the InfluxData repository for stable packages
RUN echo -e "[influxdata]\nname = InfluxData Repository - Stable\nbaseurl = https://repos.influxdata.com/stable/\$basearch/main\nenabled = 1\ngpgcheck = 1\ngpgkey = https://repos.influxdata.com/influxdata-archive_compat.key" > /etc/yum.repos.d/influxdata.repo

RUN dnf update -y && \
    dnf install -y epel-release \ 
    dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf update -y && \
    dnf clean all -y

RUN dnf install -y \
    openldap \
    openldap-servers \
    openldap-clients \
    krb5-server \
    krb5-server-ldap \
    krb5-workstation \
    firewalld \
    rsyslog \
    vim \
    ncurses \
    telegraf && \
    dnf clean all -y

COPY ./openldap-data /srv/openldap
COPY ./telegraf /srv/telegraf

# Expose necessary ports for LDAP, Kerberos and other services
EXPOSE 88 464 389 636 22 9273

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
