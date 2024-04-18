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
    oddjob-mkhomedir \
    vim \
    ncurses && \
    dnf clean all -y

ENTRYPOINT ["tail", "-f", "/dev/null"]
