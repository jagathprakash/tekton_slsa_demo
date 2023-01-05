#!/bin/sh
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
# The Google Service Account which will be used to access GCP resource like ArtifactRegistry and KMS.
export GSA_NAME=jp-gsa
# The Kubernets service account which will be tied to the GSA.
export KSA_NAME=jp-ksa
# The name of the repo in GCP's ArtifactRegistry, which will be used to upload artifacts created by this demo.
export CLOUD_REPO=jp-repo
# The GCP project_id
export PROJECT_ID=jagathprakash-test
# export KO_DOCKER_REPO='gcr.io/jagathprakash-test'
# The name of the cluster created in GCP.
export CLUSTER_NAME=slsa-demo-cluster
# The zone in which the cluster is created.
export ZONE=us-central1
# The namespace in which the Tekton resources are created.
export NAMESPACE=default
# The KMS key ring.
export KEYRING=pj-keyring
# The KMS key.
export KEY=pj-key
# A reference to the KMS key as used in APIs.
export KMS_REF=gcpkms://projects/${PROJECT_ID}/locations/us/keyRings/${KEYRING}/cryptoKeys/${KEY}/cryptoKeyVersions/1
# The builder_id to be used for the build.
export BUILDER_ID=www.example.org/tekton-builder