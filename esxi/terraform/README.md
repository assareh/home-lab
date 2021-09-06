# ESXi Home Lab Terraform

Terraform configuration to provision the Nomad/Consul/Vault servers based on the Packer VM templates. This code depends on the community provided [esxi](https://registry.terraform.io/providers/josenk/esxi/latest) Terraform provider. Please note the [requirements](https://github.com/josenk/terraform-provider-esxi#requirements) for using this provider, including ovftool. If you would like to provision this using Terraform Cloud, you'll need a Business tier entitlement to enable Terraform Cloud Agents (assuming your ESXi host is not reachable from the internet, and it probably shouldn't be.)

As described in the repository [README](../../README.md), I resort to using statically assigned IP addresses in this environment. I have configured static assignments on my router based on MAC address as listed below, and specify the MAC address for each machine in the terraform code.

There is a [script](./setup_castle.tpl) that is run on each machine once it's provisioned. This is a one time bootstrap that uses the provided secret_id to authenticate to Vault and fetch any certificates and other secrets as needed, as well as update the `cluster_addr` value in the [Vault config](../packer/castle/files/vault.hcl). The primary need for this provisioner is due to the fact that some configuration can only be done after the system's IP address is known. 

## High level steps
Since I don't have an auto scaling group type of structure, I am using a blue/green methodology to perform upgrades.
1. Deploy blue nodes with the latest machine image
2. To perform an upgrade, deploy green nodes with the latest image, validate, then drain and destroy the blue nodes
3. To upgrade again, deploy blue nodes with the latest image, validate, then drain and destroy green nodes
4. Repeat steps 2-3 ad infinitum

## Prerequisites
An ESXi host
Recommended resources

## First run
Review the terraform code *carefully*. Provide values for terraform variables.

If you do not wish to mirror the ZFS volume on the NAS across two datastores, remove the `nas_disk2` resource, and change the first line of the nas remote-exec provisioner to `sudo zpool create data /dev/sdb`.

Deploy it with `terraform apply`. It may take 10-15 minutes to complete.

Once provisioning is complete, initialize Vault:
```
export VAULT_ADDR='https://192.168.0.101:8200'
vault operator init -recovery-shares=1 -recovery-threshold=1
```

Optionally follow the Vault [Disaster Recovery Replication Setup](https://learn.hashicorp.com/tutorials/vault/disaster-recovery) Learn guide to configure Vault Enterprise Disaster Recovery.

You should have fully operational Consul, Nomad, and Vault clusters. Now go run [some jobs](../../nomad-jobs)!

## Subsequent runs
1. Run [Packer](../packer) to generate a new version of the template
2. Update tfvars to add new nodes
     * Update `template_blue` OR `template_green` with the new template name
     * Edit `nodes_blue` or `nodes_green` as necessary to add 3 new nodes
          The format is 
```
{
  Castle-1 = "00:0C:29:00:00:0A"
  Castle-2 = "00:0C:29:00:00:0B"
  Castle-3 = "00:0C:29:00:00:0C"
}
OR
{
  Castle-4 = "00:0C:29:00:00:0D"
  Castle-5 = "00:0C:29:00:00:0E"
  Castle-6 = "00:0C:29:00:00:0F"
}
```
3. Terraform plan and apply
4. Validate
     * Consul cluster health (Autopilot should do its thing)
     * Nomad cluster health (Autopilot should do its thing)
     * Vault cluster unseal and health
5. Update tfvars to remove old nodes
     * Edit `nodes_blue` OR `nodes_green` as necessary to remove 3 old nodes
          The format is
```
{ }
```
6. Terraform plan and apply
