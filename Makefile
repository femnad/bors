all: init

init:
	terraform init -backend-config=gcs-backend-config.secret
