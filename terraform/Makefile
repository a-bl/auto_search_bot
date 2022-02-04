STATE_NAME=auto-search-bot-dev

init:
	-terraform init || \
		${MAKE} bare_init
bare_init:
	aws s3api create-bucket --bucket ${STATE_NAME} --create-bucket-configuration LocationConstraint=eu-central-1
	terraform init
	terraform import -lock=false aws_s3_bucket.state ${STATE_NAME}
	terraform apply -lock=false -target=aws_dynamodb_table.state -auto-approve
apply:
	terraform apply -auto-approve
destroy:
	terraform state rm \
		aws_s3_bucket.state \
		aws_s3_bucket_public_access_block.state \
		aws_dynamodb_table.state
	terraform destroy -auto-approve
	aws dynamodb delete-table --table-name ${STATE_NAME}
	rm .terraform/terraform.tfstate
