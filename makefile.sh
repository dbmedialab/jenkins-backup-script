#!/bin/bash
set -euo pipefail

PREFIX="$(pwd)"
BACKUP_DIR="$PREFIX/run"
BACKUP_FILE="backup.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
function log {
    echo "$@" >&2
}

function bail {
    local msg="${1-}"
    if [ -n "$msg" ]; then
        log "$msg"
    fi
    echo "Exiting due to error" >&2
    exit 1
}

function clean {
    log "clean:"
    rm -rf "$BACKUP_DIR"
}

function backup {
    log "backup:"
    if [ -z "$JENKINS_HOME" ]; then
        bail '$JENKINS_HOME is not set!'
    fi
    log "  Backing up \$JENKINS_HOME"
    mkdir -p "$BACKUP_DIR"
    ./jenkins-backup.sh "$JENKINS_HOME" "$BACKUP_PATH" || bail "  Backup failed"
}

function backup_exists {
    if [ -f "$BACKUP_PATH" ]; then
        return 0
    else
        return 1
    fi
}

function require_backup {
    if backup_exists; then
        return 0
    else
        backup
    fi  
}

function verify {
    log "verify:"
    require_backup
    log "  Verifying backup archive integrity"
    tar -tzf "$BACKUP_PATH" > /dev/null || bail "  Invalid backup archive!"
}

function container_age {
    local container_name="${1-}"
    if [ -z "$container_name" ]; then
        bail "Container name is required for container_age"
    fi
    local container_timestamp="$(docker inspect -f '{{.Created}}' "$container_name" 2>/dev/null)"
    if [ -z "$container_timestamp" ]; then
        return 1
    fi
    
    local created_unix="$(date -u -d "$container_timestamp" +"%s")"
    local now_unix="$(date -u +"%s")"
    echo "$(($now_unix - $created_unix))"
}

function gcloud_auth_clean {
    log "gcloud_auth_clean:"
    log "  Removing existing gcloud-config container"
    docker container rm gcloud-config
}

function gcloud_auth {
    log "gcloud_auth:"
    docker run -ti --name gcloud-config 'google/cloud-sdk:latest' gcloud auth login
}

function gcloud_auth_if_necessary {
    log "gcloud_auth_if_necessary:"
    local container_age="$(container_age "gcloud-config")"
    if [ -z "$container_age" ]; then
        gcloud_auth
    elif [[ $container_age -gt 3600 ]]; then
        # If the container is older than an hour, re-create
        gcloud_auth_clean
        gcloud_auth
    else
        log "  Reusing existing gcloud-auth container"
    fi   
}

function upload_to_gs {
    log "upload_to_gs:"
    require_backup
    log "  Uploading archive to Google Storage"
    docker run --rm -t \
	-v "${BACKUP_DIR}:/backup" \
	'google/cloud-sdk:latest' \
	gsutil cp "/backup/${BACKUP_FILE}" \
        gs://medialab-jenkins-backups/full/backup_$(date +"%Y%m%d%H%M%S").tar.gz
}


function dispatch {
    local action="${1-}"
    case $action in
        "clean")
            clean
            ;;
        "backup")
            backup
            ;;
        "verify")
            verify
            ;;
        "gcloud_auth")
            gcloud_auth
            ;;
        "gcloud_auth_clean")
            gcloud_auth_clean
            ;;
        "gcloud_auth_if_necessary")
            gcloud_auth_if_necessary
            ;;
        "upload_to_gs")
            upload_to_gs
            ;;
        *)
            bail "Unknown action '$action'"
            ;;
    esac
}

function parse_args {
    local arg="${1-}"
    while [ -n "$arg" ]; do
        dispatch "$arg"
        shift
        arg="${1-}"
    done
}

parse_args $@
