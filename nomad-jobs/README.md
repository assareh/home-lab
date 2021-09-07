# Nomad Jobs for Home Lab

A set of Nomad job files for services and applications I run in my home lab. These may require modification to work in your environment.

Storage is provided via Florian Apolloner's [NFS CSI Plugin](https://gitlab.com/rocketduck/csi-plugin-nfs) which should work with any NFS share. Please review his documentation for details on how to configure and use it.

## Notes
~~There is Terraform code here if you'd like to manage these with Terraform and the Nomad provider, however this is not required.~~ This is temporarily unavailable as the Nomad provider doesn't seem to support CSI volumes yet. GH issue TBC.

### Best practices
- Explicitly specify the tag version for more controlled updates/upgrades.

### GitLab
- [Configuring external URL](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/settings/configuration.md#configuring-the-external-url-for-gitlab)
- Looks like i need to update the readiness probes to IP whitelist per https://docs.gitlab.com/ee/user/admin_area/monitoring/health_check.html#access-token-deprecated

### Grafana
Need to update dashboards location

### hclfmt-all
Script to invoke linter on all nomad files in the folder. Requires the deprecated [hclfmt](https://github.com/fatih/hclfmt) be installed and available in your path.

### Pi-hole
I am using [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation) as the resolver, this is not required and can be removed.

### Splunk
https://docs.splunk.com/Documentation/Splunk/8.2.1/Admin/MoreaboutSplunkFree

### Traefik
I am using the [Let's Encrypt integration](https://doc.traefik.io/traefik/https/acme/) to automatically obtain and renew a publicly signed wildcard certificate. This is not required. You'll need to search and replace all tags with your domain name.

[Keepalived](https://www.keepalived.org) is used to provide a consistent static VIP (virtual addresss). This is useful if you would like to expose a port on your router and forward traffic to the Traefik ingress.

#### Issues
- Watching [#7430](https://github.com/traefik/traefik/issues/7430) for a UDP fix

## To do list
* document "dnsmasq.cname=true"
* roll out consul connect now that traefik 2.5
* update stanzas, enhance service checks, and https://www.nomadproject.io/docs/job-specification/check_restart
* can send docker logs to splunk https://docs.docker.com/config/containers/logging/configure/

## Links and References
Examples here:
- https://github.com/scarolan/migrate-vmware-to-nomad/blob/master/nomad-job.hcl
- https://github.com/angrycub/nomad_example_jobs/tree/main/qemu
- https://github.com/jescholl/nomad
