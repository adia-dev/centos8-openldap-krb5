# Dockerfile for CentOS 8 with OpenLDAP and Kerberos
# This image provides a robust CentOS 8 base with integrated OpenLDAP and Kerberos for secure directory services and authentication management. Ideal for development, testing, and production environments requiring LDAP and Kerberos setup.

FROM centos:8

LABEL org.opencontainers.image.title="CentOS 8 with OpenLDAP and Kerberos" \
    org.opencontainers.image.description="A CentOS 8 Docker image equipped with OpenLDAP and Kerberos 5, configured for easy setup and management of LDAP and Kerberos services. Perfect for secure authentication and directory services." \
    org.opencontainers.image.vendor="adiadev" \
    org.opencontainers.image.authors="adiadev" \
    org.opencontainers.image.url="https://hub.docker.com/r/adiadev/centos-openldap-krb5" \
    org.opencontainers.image.documentation="https://github.com/adiadev/centos-openldap-krb5/README.md" \
    org.opencontainers.image.source="https://github.com/adiadev/centos-openldap-krb5" \
    org.opencontainers.image.version="0.1.0" \
    org.opencontainers.image.licenses="MIT"

# Update CentOS repositories to use vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Install dependencies
RUN dnf update -y && \
    dnf install -y \
    krb5-server \
    krb5-server-ldap \
    krb5-workstation \
    vim \
    ncurses && \
    dnf clean all -y

# Install the openldap packages
RUN dnf install -y \
    https://ftp.osuosl.org/pub/osl/repos/yum/8/openldap/x86_64/openldap-2.4.50-5.el8.x86_64.rpm \
    https://ftp.osuosl.org/pub/osl/repos/yum/8/openldap/x86_64/openldap-clients-2.4.50-5.el8.x86_64.rpm \
    https://ftp.osuosl.org/pub/osl/repos/yum/8/openldap/x86_64/openldap-servers-2.4.50-5.el8.x86_64.rpm

# Expose necessary ports for LDAP, Kerberos and other services
EXPOSE 88 464 389 636 22

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
