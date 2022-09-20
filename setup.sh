#!/bin/sh
set -e
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export GSA_NAME=jp-tk-gsa
export KSA_NAME=jp-tk-ksa
export CLOUD_REPO=jp-tk-repo
export PROJECT_ID=jagathprakash-test
export PROJECT=jagathprakash-test
export KO_DOCKER_REPO='gcr.io/jagathprakash-test'
export CLUSTER_NAME=tekton
export NAMESPACE=default
export KEYRING=pj-tk-keyring
export KEY=pj-tk-key
export KMS_REF=gcpkms://projects/jagathprakash-test/locations/global/keyRings/${KEYRING}/cryptoKeys/${KEY}

# GCP settings
# Ensure IAM is enabled
gcloud services enable iam.googleapis.com
# Create a Kubernetes Service account
if kubectl get serviceAccount "${KSA_NAME}"; then
  echo "KSA ${KSA_NAME} already exists"
else 
  kubectl create serviceaccount "${KSA_NAME}" --namespace "${NAMESPACE}"
fi

# Create a GCloud Service account
if gcloud iam service-accounts list | grep "${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"; then
  echo "GSA ${GSA_NAME} already exists"
else 
  gcloud iam service-accounts create "${GSA_NAME}" \
    --description="Tekton Build-time Service Account" \
    --display-name="Tekton Builder"
fi

# Set up Artifact Registry: create a docker repository and authorize the
# builder to push images to it.
if gcloud artifacts repositories list | grep "${CLOUD_REPO}"; then
  echo "Repo ${CLOUD_REPO} already exists"
else
  gcloud artifacts repositories create "${CLOUD_REPO}" \
      --repository-format=docker --location="us"
fi

# Provide necessary permissions to the KSA Service account.
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member "serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role "roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role "roles/cloudkms.cryptoOperator"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/cloudkms.viewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/containeranalysis.admin"

# Add an IAM Policy Binding to let the KSA have access to the GSA.
gcloud iam service-accounts add-iam-policy-binding $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/$KSA_NAME]"

# Annotate the KSA to point to the GSA to use.
kubectl annotate serviceaccount $KSA_NAME \
  --overwrite \
  --namespace $NAMESPACE \
  iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com


# Configure Key Management Service.
# Ensure KMS is available.
gcloud services enable cloudkms.googleapis.com 
echo "Checking for existence of KEYRING ${KEYRING}..."
if gcloud kms keyrings describe "${KEYRING}" --location "us"; then
  echo "KEYRING ${KEYING} found."
else
  gcloud kms keyrings create "${KEYRING}" --location "us"
  echo "KEYRING ${KEYRING} created successfully."
fi

if gcloud kms keys list --keyring=${KEYRING} --location=us; then
  echo "KEY ${KEY} already exists"
else
  gcloud kms keys create "${KEY}" \
    --keyring "${KEYRING}" \
    --location "us" \
    --purpose "asymmetric-signing" \
    --default-algorithm "rsa-sign-pkcs1-2048-sha256"
fi

# install pipelines
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# install chains
kubectl apply --filename https://storage.googleapis.com/tekton-releases/chains/previous/v0.11.0/release.yaml

kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"artifacts.taskrun.format": "in-toto"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"artifacts.oci.format": "simplesigning"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"artifacts.taskrun.signer": "kms"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"artifacts.oci.signer": "kms"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"signers.kms.kmsref": "'"${KMS_REF}"'"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"artifacts.taskrun.storage": "grafeas"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"artifacts.oci.storage": "grafeas"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"storage.grafeas.projectid": "'"$PROJECT_ID"'"}}'
kubectl patch configmap chains-config -n tekton-chains -p='{"data":{"storage.grafeas.noteid": "tktn_slsa_demo_note"}}'

# install tasks from hub
tkn hub install task git-clone
tkn hub install task kaniko