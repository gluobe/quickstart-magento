source "amazon-ebs" "magento2" {
    ami_name = "packer-magento2-{{timestamp}}"
    ami_users = ["576148397492","895248839606","657625821559"]
    profile = "imb-QAL"
    region = "us-east-2"
    instance_type = "t2.large"
    source_ami_filter {
        filters = {
          virtualization-type = "hvm"
          name =  "*amzn2-ami-hvm-*"
          root-device-type = "ebs"
        }
        owners = ["amazon"]
        most_recent = true
    }
    communicator = "ssh"
    ssh_username = "ec2-user"
}

# folder/build.pkr.hcl
# A build starts sources and runs provisioning steps on those sources.
build {
  sources = [
    # there can be multiple sources per build */
    "source.amazon-ebs.magento2"
  ]
 # All provisioners and post-processors have a 1:1 correspondence to their
 # current layout. The argument name (ie: inline) must to be unquoted
 # and can be set using the equal sign operator (=).
  provisioner "file" {
    destination = "/tmp/"
    source      = "./files/"
  }
  provisioner "shell" {
    script = "./scripts/install_magento.sh"
  }
}
