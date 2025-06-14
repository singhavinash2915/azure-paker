variable "subscription_id" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type    = string
  default = ""
}

variable "client_id" {
  type    = string
  default = ""
}

variable "client_secret" {
  sensitive = true
  type      = string
  default   = ""
}

variable "user_data_file" {
  type    = string
  default = ""
}


source "azure-arm" "autogenerated_1" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  build_resource_group_name         = "rg-core-tools-nprd-eus2"
  communicator                      = "winrm"
  image_offer                       = "WindowsServer"
  image_publisher                   = "MicrosoftWindowsServer"
  image_sku                         = "2019-Datacenter"
  managed_image_name                = "windows-golden-nprd-eus2-001"
  managed_image_resource_group_name = "rg-core-tools-nprd-eus2"
  os_type                           = "Windows"
  vm_size                           = "Standard_D2_v2"
  winrm_insecure                    = true
  winrm_timeout                     = "5m"
  winrm_use_ssl                     = true
  winrm_username                    = "packer"
  skip_create_build_key_vault       = true

  # Powershell script which adds a WinRM certificate to the Virtual Machine 
  custom_script = "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -Command \"$userData = (Invoke-RestMethod -H @{'Metadata'='True'} -Method GET -Uri 'http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-01-01&format=text'); $contents = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($userData)); set-content -path c:\\Windows\\Temp\\userdata.ps1 -value $contents; . c:\\Windows\\Temp\\userdata.ps1;\""
  #user_data_file = var.user_data_file 
  user_data_file = "packer/scripts/windows/userdata.ps1"
}

build {
  sources = ["source.azure-arm.autogenerated_1"]

  provisioner "powershell" {
    inline = ["Add-WindowsFeature Web-Server", "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit", "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"]
  }

}