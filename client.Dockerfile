FROM centos:8

# Update CentOS repositories to use vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN dnf update -y && \
    dnf install -y epel-release \ 
    dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf update -y && \
    dnf clean all -y

RUN dnf install -y \
    openldap-clients \
    sssd \
    sssd-ldap \
    authselect \
    oddjob-mkhomedir \
    vim \
    ncurses && \
    dnf clean all -y

COPY ./setup-openldap-client /setup-openldap-client
COPY ./client.entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
