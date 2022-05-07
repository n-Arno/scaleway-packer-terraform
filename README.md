scaleway-packer-terraform
=========================

This demonstrate a quick way to build a custom image using Packer and deploy it using Terraform with the Scaleway provider.

Prerequisites:
* create a Scaleway API key and create needed environment variables (SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID, etc...)
* install Packer and Terraform cli (ie brew install packer)
* install gnu/make if needed (otherwise, just check commands in Makefile)

Note: in packer.json, the image id is found out using the Scaleway CLI and this command: `scw marketplace image get label=ubuntu_focal`
