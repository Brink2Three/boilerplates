# Terraform Proxmox Boilerplate
Hello world!

I do plan on adding additional configuration control to the boilerplate, but for now, this should allow some of the newer Proxmox people to try out Terraform. (:

Things I want to add: 
- Backup controls (PBS connection control via terraform?) ((Auto assign backup roles to instances through terraform controls???))
- Firewall control (ya ya)
- Cluster control (If I get a proxmox cluster set up. (: ) 


## Things you need to use this
- `terraform` CLI installed (google "How to install terraform")
- How to use the command line (can't help there... good luck)
- How to generate an API token for proxmox. This guide is a speedrun: https://www.youtube.com/watch?v=wK8PUp7rjzs 


# Setup
1. Copy `credentials.auto.tfvars.template` to `credentials.auto.tfvars` and add your credentials and base URL. setting a default VM password is optional. I have it there for a simple first time use.
2. run `terraform init` and ensure it connects successully installs the BPG provider.
3. run `terraform plan` and look for the changes it's making. It will probably default to adding one container and one VM. If you're ok creating them, go to step 4. If not, modify the config files.
4. run `terraform apply` to deploy the configured VMs to your Proxmox environment.

# Docs - BPG Proxmox provider

Root level: https://registry.terraform.io/providers/bpg/proxmox/latest/docs

Virtual Machine docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm

LXC Container docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container


## Import "hardware"

`terraform import TerraformProviderResourceType.ResourceName <node>/<vmid>`

## Examples
 
* Importing a container
`terraform import proxmox_virtual_environment_container.pihole-ubuntu pve/114`

* Importing a VM
`terraform import proxmox_virtual_environment_vm.testVM1 pve/221`

## LXC Container Import bug ##
After importing a container, change `"template_file_id"` from `null` to the correct template file in the terraform state file. Otherwise it will always try to replace the entire container.
IE, change the 3rd line in the following to the template.

```json
"operating_system": [
    {
    "template_file_id": "",
    "type": "ubuntu"
    }
],
``` 

> The easiest way to get what this *should* be, is to import the container, run a terraform plan, then copy the template file ID from the terraform plan "expected changes". 

If you are using the exact template ID as I am in this example, your Tfstate file would look like this:

```json
"operating_system": [
    {
    "template_file_id": "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst",
    "type": "ubuntu"
    }
],
```

## Why the BPG Provider? 
Importing existing resources in the Telmate provider seem to break worse than the BPG provider changes shown above. I have tried both. 

BPG is better. 