#!/bin/sh
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GSA_NAME=jp-gsa
export KSA_NAME=jp-ksa
export CLOUD_REPO=jp-repo
export PROJECT_ID=jagathprakash-test
export KO_DOCKER_REPO='gcr.io/jagathprakash-test'
export CLUSTER_NAME=slsa-demo-cluster
export ZONE=us-central1
export NAMESPACE=default
export KEYRING=pj-keyring
export KEY=pj-key
export KMS_REF=gcpkms://projects/${PROJECT_ID}/locations/us/keyRings/${KEYRING}/cryptoKeys/${KEY}/cryptoKeyVersions/1