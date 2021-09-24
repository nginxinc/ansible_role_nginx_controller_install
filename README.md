NGINX Controller Install Ansible Role
=========

This role installs [NGINX Controller](https://www.nginx.com/products/nginx-controller/).

Requirements
------------

* Controller tarball file from the [F5 Customer Portal](https://my.f5.com).

For the installation script to work:

* Supported operating systems: Ubuntu, Debian, CentOS, Red Hat Enterprise Linux
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
| `nginx_controller_tarball` | `""` | Source path to the Controller tarball file on the remote host. | Yes |
| `nginx_controller_install_path` | `""` | Path where the tarball is extracted on the remote host. | Yes |
| `nginx_controller_remote_source` | `"true"` | If the tarball file exists on the remote machine. | No |
| `nginx_controller_db_host` | `""` | PostgreSQL database host ip address or FQDN, unnecessary when using bundled_db. | No |
| `nginx_controller_db_port` | `"5432"` | PostgreSQL database port, unnecessary when using bundled_db. | No |
| `nginx_controller_db_user` | `""` | PostgreSQL database user, unnecessary when using bundled_db. | No |
| `nginx_controller_db_password` | `""` | PostgreSQL database password, unnecessary when using bundled_db. | No |
| `nginx_controller_apigw_cert` | `""` |  SSL/TLS cert file path, cannot be used together with self_signed_cert: true. | No |
| `nginx_controller_apigw_key` | `""` |  SSL/TLS key file path, cannot be used together with self_signed_cert: true. | No |
| `nginx_controller_tsdb_volume_type` | `""` | Backing volume for time series database. (local, nfs or aws) | Yes |
| `nginx_controller_tsdb_nfs_path` | `""` | Time series database NFS path (only if `tsdb_volume_type` is `nfs`) | No |
| `nginx_controller_tsdb_nfs_host` | `""` | Time series database NFS host (only if `tsdb_volume_type` is `nfs`) | No |
| `nginx_controller_tsdb_aws_volume_id` | `""` | Time series database AWS EBS Volume ID (only if `tsdb_volume_type` is `aws`) | No |
| `nginx_controller_configdb_volume_type` | `""` | Backing volume for config database. (local, nfs or aws) | No |
| `nginx_controller_configdb_nfs_path` | `""` | Config database NFS path (only if `configdb_volume_type` is `nfs`) | No |
| `nginx_controller_configdb_nfs_host` | `""` | Config database NFS host (only if `configdb_volume_type` is `nfs`) | No |
| `nginx_controller_configdb_aws_volume_id` | `""` | Config database AWS EBS Volume ID (only if `configdb_volume_type` is `aws`) | No |
| `nginx_controller_smtp_host` | `""` | SMTP Host for emails. | Yes |
| `nginx_controller_smtp_port` | `"25"` | SMTP Port for emails. | No |
| `nginx_controller_smtp_authentication` | `""` | Specify if SMTP needs auth (true or false). | Yes |
| `nginx_controller_smtp_user` | `""` | SMTP user (only provide if `smtp_authentication` is true). | No |
| `nginx_controller_smtp_password` | `""` | SMTP password (only provide if `smtp_authentication` is true). | No |
| `nginx_controller_smtp_use_tls` | `false` | Specify if SMTP should use https (true or false) | No |
| `nginx_controller_noreply_address` | `""` | Specify the email to show in the 'FROM' field of controller emails. | Yes |
| `nginx_controller_fqdn` | `""` | FQDN for the controller web frontend and agent communication. For example, controller.example.com. This domain name must not exceed 64 characters. | Yes |
| `nginx_controller_organization_name` | `""` | The organization name. | Yes |
| `nginx_controller_admin_firstname` | `""` | Admin user first name. | Yes |
| `nginx_controller_admin_lastname` | `""` | Admin user last name. | Yes |
| `nginx_controller_admin_email` | `""` | Admin user email. | Yes |
| `nginx_controller_admin_password` | `""` | Admin user password. | Yes |
| `nginx_controller_self_signed_cert` | `false` | Specify if the installation should create a self signed cert for TLS (true or false). | No |
| `nginx_controller_overwrite_existing_configs` | `false` | Specify if the existing config for controller should be overwritten (true or false). | No |
| `nginx_controller_auto_install_docker` | `false` | Specify if docker needs to be installed as part of the installation process (true or false). | No |
| `nginx_controller_bundled_db` | `false` | Specify if the installation process should use a bundled database (version >=3.8). | No |

> _Note_ `nginx_controller_configdb_*` options are for use with the `nginx_controller_bundled_db`,
>  and are mutually exclusive with the `nginx_controller_db_` parameters.

Dependencies
------------

No dependencies.

Example Playbook
----------------

The following playbook example will use this role to install controller. Check the [variables](#role-variables) and set the values inside `<`,`>` accordingly.

Installing Controller to a remote.
example is using Ubuntu 18.04

```yaml
## on the remote host
- hosts: controller
  remote_user: ubuntu
  become: true
  become_method: sudo
  gather_facts: true

  # Supporting su requirement for Controller installer role
  - name: Set root password to support su for Controller installation with Ubuntu
    user:
      name: root
      password: "{{ su_password | password_hash('sha512') }}"

  - name: Copy the controller tar archive to the remote host
    copy:
      src: "{{playbook_dir}}/{{nginx_controller_tarball}}"
      dest: "{{ ansible_env.HOME }}/{{nginx_controller_tarball}}"
      owner: ubuntu
      group: ubuntu
      force: true
    vars:
      nginx_controller_install_path: "{{ ansible_env.HOME }}"
      nginx_controller_tarball: "controller-installer-<>.tar.gz"

  - name: Make sure all the prerequisites are present on the remote
    apt:
      name: "{{ packages }}"
      state: present
      update_cache: true
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
      - jq
      - socat
      - conntrack
      - ebtables
      - python-pexpect  # to support ansible
      - nfs-common  # to support nfs remote volume
    tags: packages

## changing security context on the remote host to su to run the installer
- name: Install Controller
  remote_user: ubuntu
  hosts: controller
  become: true
  become_user: ubuntu
  become_method: su  # note that the become method is required to be su, you will need to support that for your distribution.
  gather_facts: false

  roles:
    - nginxinc.nginx_controller_install

  vars:
    - nginx_controller_tarball: "{{ ansible_env.HOME }}/{{nginx_controller_tarball}}"
    - nginx_controller_install_path: /usr/ubuntu
    - nginx_controller_db_host: dbhost.example.com
    - nginx_controller_db_user: "naas"
    - nginx_controller_db_password: ''
    - nginx_controller_db_enable_ssl: false
    - nginx_controller_tsdb_volume_type: nfs
    - nginx_controller_tsdb_nfs_path: "/controllerdb"
    - nginx_controller_tsdb_nfs_host: storage.internal
    - nginx_controller_smtp_host: "localhost"
    - nginx_controller_smtp_authentication: false
    - nginx_controller_smtp_use_tls: false
    - nginx_controller_noreply_address: "noreply@example.com"
    - nginx_controller_fqdn:  controller.example.com
    - nginx_controller_organization_name: "Example"
    - nginx_controller_admin_firstname: "Firstname"
    - nginx_controller_admin_lastname: "Lastname"
    - nginx_controller_admin_email: "firstname@example.com"
    - nginx_controller_admin_password: ''
    - nginx_controller_self_signed_cert: true
    - nginx_controller_overwrite_existing_configs: true
    - ansible_python_interpreter: /usr/bin/python3
    - ansible_become_password: '<some secure password>'

# pull the install log for review
- hosts: controller
  remote_user: ubuntu
  become: true
  become_method: sudo
  gather_facts: false

  tasks:
  - name: Fetch the install log
    fetch:
      src: /var/log/nginx-controller/nginx-controller-install.log
      dest: "{{playbook_dir}}/logs/"

```

You can then run `ansible-playbook nginx_controller_install.yaml` to execute the playbook.

Alternatively, you can also pass/override any variables at run time using the `--extra-vars` or `-e` flag like so `ansible-playbook nginx_controller_install.yaml -e "nginx_controller_admin_email=user@company.com nginx_controller_admin_password=notsecure nginx_controller_fqdn=controller.example.local"`

You can also pass/override any variables by passing a `yaml` file containing any number of variables like so `ansible-playbook nginx_controller_install.yaml -e "@nginx_controller_install_vars.yaml"`

Troubleshooting
-------

* Check the installation logs in `/var/log/nginx-controller/nginx-controller-install.log` on the remote. Above task example pulls those to the Ansible server.

License
-------

[Apache License, Version 2.0](./LICENSE)

Author Information
------------------

[F5 Networks](https://www.f5.com/)
