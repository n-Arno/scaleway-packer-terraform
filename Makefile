all: packer terraform

packer:
	packer build packer.json

terraform:
	terraform init
	terraform apply --auto-approve
