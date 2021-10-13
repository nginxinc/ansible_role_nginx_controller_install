# Ansible NGINX Controller Installation Role

This role installs [NGINX Controller](https://www.nginx.com/products/nginx-controller/) on your target host.

## Requirements

### NGINX Controller

NGINX Controller tarball file from the [F5 Customer Portal](https://my.f5.com).

### Ansible

* This role is developed and tested with [maintained](https://docs.ansible.com/ansible/devel/reference_appendices/release_and_maintenance.html) versions of Ansible core (above `2.11`).
* You will need to run this role as a root user using Ansible's `become` parameter. Make sure you have set up the appropriate permissions on your target hosts.
* Instructions on how to install Ansible can be found in the [Ansible website](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#upgrading-ansible-from-version-2-9-and-older-to-version-2-10-or-later).

### Molecule (Optional)

* Molecule is used to test the various functionalities of the role. The recommended version of Molecule to test this role is `3.3`.
* Instructions on how to install Molecule can be found in the [Molecule website](https://molecule.readthedocs.io/en/latest/installation.html). _You will also need to install the Molecule Docker driver._

## Installation

### Ansible Galaxy

Use `ansible-galaxy install nginxinc.nginx_controller_install` to install the latest stable release of the role on your system. Alternatively, if you have already installed the role, use `ansible-galaxy install -f nginxinc.nginx_controller_install` to update the role to the latest release.

### Git

Use `git clone https://github.com/nginxinc/ansible_role_nginx_controller_install.git` to pull the latest edge commit of the role from GitHub.

## Platforms

The NGINX Controller install Ansible role supports all platforms supported by [NGINX Controller](https://docs.nginx.com/nginx-controller/admin-guides/install/nginx-controller-tech-specs/):

```yaml
CentOS:
  - 7.4+
Debian:
  - stretch
RHEL:
  - 7.4+
Ubuntu:
  - bionic
  - focal
```

## Role Variables

| Variable | Default | Description | Required |
| -------- | ------- | ----------- | -------- |
| `nginx_controller_tarball` | `""` | Source path to the Controller tarball file on the remote host | Yes |
| `nginx_controller_install_path` | `""` | Path where the tarball is extracted on the remote host | Yes |
| `nginx_controller_remote_source` | `"true"` | If the tarball file exists on the remote machine | No |
| `nginx_controller_db_host` | `""` | PostgreSQL database host ip address or FQDN, unnecessary when using bundled_db | No |
| `nginx_controller_db_port` | `"5432"` | PostgreSQL database port, unnecessary when using bundled_db | No |
| `nginx_controller_db_user` | `""` | PostgreSQL database user, unnecessary when using bundled_db | No |
| `nginx_controller_db_password` | `""` | PostgreSQL database password, unnecessary when using bundled_db | No |
| `nginx_controller_apigw_cert` | `""` | SSL/TLS cert file path, cannot be used together with self_signed_cert: true | No |
| `nginx_controller_apigw_key` | `""` | SSL/TLS key file path, cannot be used together with self_signed_cert: true | No |
| `nginx_controller_tsdb_volume_type` | `""` | Backing volume for time series database. (local, nfs or aws) | Yes |
| `nginx_controller_tsdb_nfs_path` | `""` | Time series database NFS path (only if `tsdb_volume_type` is `nfs`) | No |
| `nginx_controller_tsdb_nfs_host` | `""` | Time series database NFS host (only if `tsdb_volume_type` is `nfs`) | No |
| `nginx_controller_tsdb_aws_volume_id` | `""` | Time series database AWS EBS Volume ID (only if `tsdb_volume_type` is `aws`) | No |
| `nginx_controller_configdb_volume_type` | `""` | Backing volume for config database. (local, nfs or aws) | No |
| `nginx_controller_configdb_nfs_path` | `""` | Config database NFS path (only if `configdb_volume_type` is `nfs`) | No |
| `nginx_controller_configdb_nfs_host` | `""` | Config database NFS host (only if `configdb_volume_type` is `nfs`) | No |
| `nginx_controller_configdb_aws_volume_id` | `""` | Config database AWS EBS Volume ID (only if `configdb_volume_type` is `aws`) | No |
| `nginx_controller_smtp_host` | `""` | SMTP Host for emails | Yes |
| `nginx_controller_smtp_port` | `"25"` | SMTP Port for emails | No |
| `nginx_controller_smtp_authentication` | `""` | Specify if SMTP needs auth (true or false) | Yes |
| `nginx_controller_smtp_user` | `""` | SMTP user (only provide if `smtp_authentication` is true) | No |
| `nginx_controller_smtp_password` | `""` | SMTP password (only provide if `smtp_authentication` is true) | No |
| `nginx_controller_smtp_use_tls` | `false` | Specify if SMTP should use https (true or false) | No |
| `nginx_controller_noreply_address` | `""` | Specify the email to show in the 'FROM' field of controller emails | Yes |
| `nginx_controller_fqdn` | `""` | FQDN for the controller web frontend and agent communication. For example, controller.example.com. This domain name must not exceed 64 characters. | Yes |
| `nginx_controller_organization_name` | `""` | The organization name | Yes |
| `nginx_controller_admin_firstname` | `""` | Admin user first name | Yes |
| `nginx_controller_admin_lastname` | `""` | Admin user last name | Yes |
| `nginx_controller_admin_email` | `""` | Admin user email | Yes |
| `nginx_controller_admin_password` | `""` | Admin user password | Yes |
| `nginx_controller_self_signed_cert` | `false` | Specify if the installation should create a self signed cert for TLS (true or false) | No |
| `nginx_controller_overwrite_existing_configs` | `false` | Specify if the existing config for controller should be overwritten (true or false) | No |
| `nginx_controller_auto_install_docker` | `false` | Specify if docker needs to be installed as part of the installation process (true or false) | No |
| `nginx_controller_bundled_db` | `false` | Specify if the installation process should use a bundled database (version >=3.8) | No |

> _Note_ `nginx_controller_configdb_*` options are for use with the `nginx_controller_bundled_db`, and are mutually exclusive with the `nginx_controller_db_` parameters.

## Example Playbook

The following playbook example will use this role to install NGINX Controller on an Ubuntu 18.04 target. Check the [variables](#role-variables) and set the values inside `<>` accordingly.

```yaml
- name: Install NGINX Controller
  remote_user: ubuntu
  hosts: controller
  become: true
  become_user: ubuntu
  become_method: su
  gather_facts: false
  tasks:
    - name: Install NGINX Controller
      include_role:
        name: nginxinc.nginx_controller_install
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

# Pull the NGINX Controller install log for review
- name: Fetch NGINX Controller install log for review
  hosts: controller
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

## Troubleshooting

Check the NGINX Controller installation logs at `/var/log/nginx-controller/nginx-controller-install.log` on the remote. Above task example pulls those to the Ansible server.

## Other NGINX Ansible Collections and Roles

You can find the Ansible NGINX Core collection of roles to install and configure NGINX Open Source, NGINX Plus, and NGINX App Protect [here](https://github.com/nginxinc/ansible-collection-nginx).

You can find the Ansible NGINX role to install NGINX OSS and NGINX Plus [here](https://github.com/nginxinc/ansible-role-nginx).

You can find the Ansible NGINX configuration role to configure NGINX [here](https://github.com/nginxinc/ansible-role-nginx-config).

You can find the Ansible NGINX App Protect role to install and configure NGINX App Protect WAF and NGINX App Protect DoS [here](https://github.com/nginxinc/ansible-role-nginx-app-protect).

You can find the Ansible NGINX Controller collection of roles to install and configure NGINX Controller [here](https://github.com/nginxinc/ansible-collection-nginx_controller).

You can find the Ansible NGINX Unit role to install NGINX Unit [here](https://github.com/nginxinc/ansible-role-nginx-unit).

## License

[Apache License, Version 2.0](https://github.com/nginxinc/ansible-role-nginx-config/blob/main/LICENSE)

## Author Information

[Alessandro Fael Garcia](https://github.com/alessfg)

[Brian Ehlert](https://github.com/brianehlert)

[Daniel Edgar](https://github.com/aknot242)

&copy; [F5 Networks, Inc.](https://www.f5.com/) 2020 - 2021
