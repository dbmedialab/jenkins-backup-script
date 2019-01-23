.PHONY: clean verify backup gcloud-auth upload-to-gs
PREFIX := $(shell pwd)
BACKUP_DIR := $(PREFIX)/run
BACKUP_FILE := backup.tar.gz
clean:
	rm -rf $(BACKUP_DIR)

backup: $(BACKUP_DIR)/$(BACKUP_FILE)

$(BACKUP_DIR)/$(BACKUP_FILE):
	@[ -n "${JENKINS_HOME}" ] || (echo '$$JENKINS_HOME variable not set!' && exit 1)
	mkdir -p $(BACKUP_DIR)
	./jenkins-backup.sh "${JENKINS_HOME}" $(BACKUP_DIR)/$(BACKUP_FILE)

gcloud-auth:
	docker container rm gcloud-config || echo "No previous container found"
	docker run -ti --name gcloud-config 'google/cloud-sdk:latest' gcloud auth login

verify: backup
	tar -tzf $(BACKUP_DIR)/$(BACKUP_FILE) > /dev/null

upload-to-gs: gcloud-auth backup
	docker run --rm -ti \
	--volumes-from gcloud-config \
	-v "$(BACKUP_DIR):/backup" \
	'google/cloud-sdk:latest' \
	gsutil cp /backup/$(BACKUP_FILE) gs://medialab-jenkins-backups/full/backup_$(shell date +"%Y%m%d%H%M%S").tar.gz
