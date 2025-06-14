variable "subscription_id" {
  type    = string
  default = "11095b56-affe-457f-a17a-8027dcd56f20"
}

variable "tenant_id" {
  type    = string
  default = "0039204c-2313-4416-bdc3-42fcf01fdbd6"
}

variable "client_id" {
  type    = string
  default = "81b07df1-21d9-4e04-9a33-679acfb4c2fc"
}

variable "client_secret" {
  sensitive = true
  type      = string
  default   = "6uq8Q~QfmCh_.-gjgdalsjugZpH3t6fpCzO2talr"
}

variable "dynatrace_install_url" {
  default = "https://dtcdn.net/one-agent-install.sh"
}

variable "dynatrace_install_params" {
  default = "--set-install-only=true --set-infra-only=false"
}

source "azure-arm" "autogenerated_1" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  image_offer     = "ubuntu-24_04-lts"
  image_publisher = "canonical"
  image_sku       = "server"
  #location                         = "East US 2"
  managed_image_name                = "ubuntu-golden-nprd-eus2-001"
  managed_image_resource_group_name = "rg-core-tools-nprd-eus2"
  os_type                           = "Linux"
  vm_size                           = "Standard_DS2_v2"
  build_resource_group_name         = "rg-core-tools-nprd-eus2"
}

build {
  sources = ["source.azure-arm.autogenerated_1"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline          = ["apt-get update", "apt-get upgrade -y", "apt-get -y install nginx"]
    inline_shebang  = "/bin/sh -x"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
        "curl -sSL https://kwi83437.apps.dynatrace.com/ui/apps/dynatrace.classic.deploy.oneagent/rest/deployment/installer/agent/unix/default/latest?arch=x86 -o /opt/one-agent-install.sh",
        "chmod +x /opt/one-agent-install.sh"
      ]
  }  

  provisioner "shell"  {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
        "if command -v apt-get >/dev/null; then",
        "  curl -o /tmp/falcon-sensor.deb '{{user `crowdstrike_pkg_url`}}'",
        "  dpkg -i /tmp/falcon-sensor.deb || apt-get install -f -y",
        "  rm -f /tmp/falcon-sensor.deb",
        "elif command -v yum >/dev/null; then",
        "  curl -o /tmp/falcon-sensor.rpm '{{user `crowdstrike_rpm_url`}}'",
        "  yum install -y /tmp/falcon-sensor.rpm",
        "  rm -f /tmp/falcon-sensor.rpm",
        "fi",
        "/opt/CrowdStrike/falconctl -s --cid=",
        "systemctl stop falcon-sensor"
      ]
    }


  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    script          = "packer/scripts/ubuntu/prep.sh"
  }
  # provisioners = [
  #   {
  #     "type" : "shell",
  #     "inline" : ["sudo apt-get update", "apt-get -y install nginx", "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
  #   },
  #   # {
  #   #   "type" : "file",
  #   #   "source" : "webapp/",
  #   #   "destination" : "/var/www/html/"
  #   # },
  #   {
  #     "type" : "shell",
  #     "script" : "scripts/ubuntu/prep.sh",
  #     "execute_command" : "echo 'packer' | sudo -S sh -c '{{.Vars}} {{.Path}}'"
  #   },
  #   # {
  #   #   "type" : "ansible",
  #   #   "playbook_file" : "ansible/configure.yml"
  #   # }
  # ]

}