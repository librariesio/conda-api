#!/bin/bash

set -e

REVISION=$(git show-ref origin/master |cut -f 1 -d ' ')
TAGGED_IMAGE=gcr.io/${GOOGLE_PROJECT}/conda-api:${REVISION}
gcloud --quiet container images describe ${TAGGED_IMAGE} || { status=$?; echo "Container not finished building" >&2; exit $status; }

gcloud --quiet container images add-tag ${TAGGED_IMAGE} gcr.io/${GOOGLE_PROJECT}/conda-api:latest

kubectl set image deployment/conda-service conda-api-container=${TAGGED_IMAGE}
