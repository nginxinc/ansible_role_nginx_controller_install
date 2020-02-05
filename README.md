NGINX Controller Install Ansible Role
=========

This role installs [NGINX Controller](https://www.nginx.com/products/nginx-controller/).

Requirements
------------

* Controller tarball file from the [NGINX Customer Portal](https://cs.nginx.com/login).

For the installation script to work:

* Supported operating systems: Ubuntu, Debian, Centos, Red Hat Enterprise Linux
* Postgres 9.5 with user credentials and permissions to allow creation of databases, write, read.
* BASH >= 4.0
* Docker Community Edition 18.09.0 or later  (installer with install for you if missing)
* Kubernetes 1.15.5  (recommend allowing installer to install Kubernetes for you)
* Installed following CLI tools on the Controller remote node:
  * curl or wget, jq, envsubst (provided by the gettext package)
  * awk, bash (4.0 or later), getent, grep, gunzip (provided by the gzip package), less, openssl, sed, tar
  * base64, basename, cat, dirname, head, id, mkdir, numfmt, sort, tee (all provided by the coreutils package)

* the full prerequisites can be reviewed [here](https://docs.nginx.com/nginx-controller/admin-guide/installing-nginx-controller/)
  
Role Variables
--------------

| Variable | Default | Description | Required |
| -------- | ------- | ----------- | -------- |
| `ctrl_tarball_src` | `""` | Source path to the Controller tarball file on the remote host. | Yes |
| `ctrl_install_path` | `""` | Path where the tarball is extracted on the remote host. | Yes |
| `db_host` | `""` | PostgreSQL database host ip address or FQDN. | Yes |
| `db_port` | `"5432"` | PostgreSQL database port. | No |
| `db_user` | `""` | PostgreSQL database user. | Yes |
| `db_password` | `""` | PostgreSQL database password. | Yes |
| `apigw_cert` | `""` |  SSL/TLS cert file path, cannot be used together with self_signed_cert: true. | No |
| `apigw_key` | `""` |  SSL/TLS key file path, cannot be used together with self_signed_cert: true. | No |
| `tsdb_volume_type` | `""` | Backing volume for time series database. (local, nfs or aws) | Yes |
| `tsdb_nfs_path` | `""` | Time series database NFS path (only if `tsdb_volume_type` is `nfs`) | No |
| `tsdb_nfs_host` | `""` | Time series database NFS host (only if `tsdb_volume_type` is `nfs`) | No |
| `tsdb_aws_volume_id` | `""` | Time series database AWS EBS Volume ID (only if `tsdb_volume_type` is `aws`) | No |
| `smtp_host` | `""` | SMTP Host for emails. | Yes |
| `smtp_port` | `"25"` | SMTP Port for emails. | Yes |
| `smtp_authentication` | `""` | Specify if SMTP needs auth (true or false). | Yes |
| `smtp_user` | `""` | SMTP user (only provide if `smtp_authentication` is true). | No |
| `smtp_password` | `""` | SMTP password (only provide if `smtp_authentication` is true). | No |
| `smtp_use_tls` | `false` | Specify if SMTP should use https (true or false) | Yes |
| `noreply_address` | `""` | Specify the email to show in the 'FROM' field of controller emails. | Yes |
| `fqdn` | `""` | FQDN for the controller web frontend and agent communication. For example, controller.example.com. | Yes |
| `organization_name` | `""` | The organization name. | Yes |
| `admin_firstname` | `""` | Admin user first name. | Yes |
| `admin_lastname` | `""` | Admin user last name. | Yes |
| `admin_email` | `""` | Admin user email. | Yes |
| `admin_password` | `""` | Admin user password. | Yes |
| `self_signed_cert` | `false` | Specify if the installation should create a self signed cert for TLS (true or false). | No |
| `overwrite_existing_configs` | `false` | Specify if the existing config for controller should be overwritten (true or false). | No |
| `auto_install_docker` | `false` | Specify if docker needs to be installed as part of the installation process (true or false). | No |

Dependencies
------------

No dependencies.

Example Playbook
----------------

The following playbook example will use this role to install controller. Check the [variables](#role-variables) and set the values inside `<`,`>` accordingly.

Installing Controller to a remote.
example is using Ubuntu 18.04

```yaml
## on the Ansible host
- hosts: localhost
  gather_facts: false

  tasks:
  - name: generate password hash # https://askubuntu.com/questions/982804/mkpasswd-m-sha-512-produces-incorrect-login
    expect:
      echo: yes
      command: /bin/bash -c "mkpasswd --method=sha-512 | sed 's/\$/\\$/g'"
      responses:
        (?i)password: '<some secure password>'
    register: password_hash

## on the remote host
- hosts: controller
  remote_user: ubuntu
  become: yes
  become_method: sudo
  gather_facts: yes

  # supporting su requirement for Controller installer role
  - name: set root password to support su for Controller installation with Ubuntu
    user:
      name: root
      password: hostvars['localhost']['password_hash'].stdout_lines[1]

  - name: copy the controller tar archive to the remote host
    copy:
      src: "{{playbook_dir}}/{{controller_tarball}}"
      dest: "{{ctrl_install_path}}/{{controller_tarball}}"
      owner: ubuntu
      group: ubuntu
      force: yes
    vars:
      ctrl_install_path: "/home/ubuntu"
      controller_tarball: "controller-installer-<>.tar.gz"

  - name:  make sure all the prerequisites are present on the remote
    apt:
      name: "{{ packages }}"
      state: present
      update_cache: yes
    vars:
      packages:
      - gettext
      - bash
      - gzip
      - coreutils
      - grep
      - less
      - sed
      - tar
      - python-pexpect  # to support ansible
      - nfs-common  # to support nfs remote volume
    tags: packages

## changing security context on the remote host to su to run the installer
- name: install controller
  remote_user: ubuntu
  hosts: controller
  become: yes
  become_user: ubuntu
  become_method: su  # note that the become method is required to be su, you will need to support that for your distribution.
  gather_facts: false

  roles:
    - nginxinc.nginx_controller_install

  vars:
    - ctrl_tarball_src: "{{ctrl_install_path}}/{{controller_tarball}}"
    - ctrl_install_path: /home/ubuntu
    - remote_src: yes
    - db_host: dbhost.example.com
    - db_port: "5432"
    - db_user: "naas"
    - db_password: ''
    - tsdb_volume_type: nfs
    - tsdb_nfs_path: "/controllerdb"
    - tsdb_nfs_host: storage.internal
    - smtp_host: "localhost"
    - smtp_port: "25"
    - smtp_authentication: false
    - smtp_use_tls: false
    - noreply_address: "noreply@example.com"
    - fqdn:  controller.example.com
    - organization_name: "Example"
    - admin_firstname: "Firstname"
    - admin_lastname: "Lastname"
    - admin_email: "firstname@example.com"
    - admin_password: ''
    - self_signed_cert: true
    - overwrite_existing_configs: true
    - auto_install_docker: true
    - controller_tarball: "controller-installer-<>.tar.gz"
    - ansible_python_interpreter: /usr/bin/python3
    - ansible_become_password: '<some secure password>'

# pull the install log for review
- hosts: controller
  remote_user: ubuntu
  become: yes
  become_method: sudo
  gather_facts: false

  tasks:
  - name: fetch the install log
    fetch:
      src: /var/log/nginx-controller/nginx-controller-install.log
      dest: "{{playbook_dir}}/logs/"

```

Troubleshooting
-------

* Check the installation logs in `/var/log/nginx-controller/nginx-controller-install.log` on the remote.  Above task example pulls those to the Ansible server.

License
-------

[Apache License, Version 2.0](./LICENSE)

Author Information
------------------

[F5 Networks](https://www.f5.com/)
