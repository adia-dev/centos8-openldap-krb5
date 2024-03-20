# 🐳 CentOS8 OpenLDAP-Krb5 Docker Container

This Docker container is crafted on CentOS 8, integrating OpenLDAP and Kerberos 5. It's meticulously configured to enable access to systemd, facilitating the management of services like slapd through systemctl commands within the container's environment.

## 📜 Description

Leveraging the robustness of CentOS as its foundation, this project is aimed at simplifying the deployment and management of LDAP services within a containerized ecosystem. The inclusion of systemd within the Docker container streamlines service management, making it more efficient to administer slapd operations.

## 🛠️ Build Instructions

Whether you're building locally or pulling directly from Docker Hub, here's how you get started:

- **Build Locally:**
  ```
  docker build -t centos-openldap-krb5 --platform=linux/amd64 .
  ```
- **Pull from Docker Hub:**
  ```
  docker pull adiadev/centos-openldap-krb5:latest
  ```

## ▶️ Running the Container

To run the container with systemd access:

```
docker run -d -h example.com --platform=linux/amd64 --privileged=true centos-openldap-krb5
```

Here's what each parameter does:

- `-d`: Detached mode, allowing the container to run in the background.
- `-h example.com`: Sets the container's hostname (feel free to customize this).
- `--platform=linux/amd64`: Specifies the container's architecture (adjust as needed, I had to specify this for my Mac with an Apple Silicon chip).
- `--privileged=true`: Enables privileged access for interacting with systemd.

## 🛠 Managing Services

For managing the OpenLDAP service within your container:

```
docker exec -it <container_id> systemctl enable slapd
docker exec -it <container_id> systemctl start slapd
docker exec -it <container_id> systemctl status slapd
```

Alternatively, for direct command line access within the container:

```
docker exec -it <container_id> /bin/bash

# Then run the following commands within the container's shell
systemctl enable slapd
systemctl start slapd
systemctl status slapd
```

## 📝 Notes

This container setup is intended for development and testing environments, offering a sandbox for LDAP and Kerberos experiments and learning.
