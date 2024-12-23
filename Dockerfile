FROM centos:8

# Update CentOS repositories to use vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Add the InfluxData repository to be able to install telegraf
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
    passwd \
    rsyslog \
    vim \
    ncurses \
    telegraf && \
    dnf clean all -y

# Install ldapscripts
RUN curl -o ldapscripts.rpm https://rpmfind.net/linux/openmandriva/cooker/repository/x86_64/unsupported/release/ldapscripts-2.0.8-1-omv4002.noarch.rpm && \
    dnf localinstall -y ldapscripts.rpm

COPY ./setup-openldap /setup-openldap
COPY ./telegraf /var/lib/telegraf/
COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Expose necessary ports for LDAP and telegraf
EXPOSE 389 9273

ENTRYPOINT ["/entrypoint.sh"]
