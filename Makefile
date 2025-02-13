.PHONY: setup clean deploy

setup:
	@echo "Construyendo la AMI con Packer..."
	cd packer && \
	AMI_ID=$$(packer build -machine-readable packer.pkr.hcl | tee /dev/tty | awk -F, '/artifact,0,id/ {split($$6, a, ":"); print a[2]}'); \
	echo "AMI generada: $$AMI_ID"; \
	echo "custom_ami = \"$$AMI_ID\"" > ../terraform/terraform.tfvars; \
	echo "Inicializando y aplicando Terraform..."; \
	cd ../terraform && terraform init && terraform plan && terraform apply -auto-approve; \
	INSTANCE_IP=$$(cd ../terraform && terraform output -raw instance_public_ip); \
	echo "IP de la instancia: $$INSTANCE_IP"; \
	echo "Usando la clave privada generada en terraform_generated_key.pem"; \
	echo "Esperando 30 segundos para que la instancia inicie..." && sleep 30; \
	echo "Preparando comando de Ansible para desplegar Apollo Server..."; \
	CMD="ansible-playbook -i \"$$INSTANCE_IP,\" -u ubuntu --private-key terraform_generated_key.pem --ssh-extra-args=\"-o StrictHostKeyChecking=no\" \"playbook.yml\""; \
	echo "Comando a ejecutar: $$CMD"; \
	cd ../ansible && eval "$$CMD"

deploy:
	@echo "Obteniendo la IP de la instancia desde Terraform..."
	INSTANCE_IP=$$(cd terraform && terraform output -raw instance_public_ip); \
	echo "Desplegando en la instancia con IP: $$INSTANCE_IP"; \
	cd ansible && ansible-playbook -i "$$INSTANCE_IP," -u ubuntu --private-key terraform_generated_key.pem --ssh-extra-args="-o StrictHostKeyChecking=no" playbook.yml

clean:
	@echo "Destruyendo infraestructura creada por Terraform..."
	@cd terraform && terraform destroy -auto-approve
	@echo "Borrando la AMI generada..."
	@if [ -f terraform/terraform.tfvars ]; then \
		AMI_ID=$$(grep 'custom_ami' terraform/terraform.tfvars | cut -d '"' -f2); \
		echo "Desregistrando AMI: $$AMI_ID"; \
		aws ec2 deregister-image --image-id $$AMI_ID; \
	else \
		echo "No se encontró terraform.tfvars, no se puede eliminar la AMI"; \
	fi
	@rm -f terraform/terraform.tfvar