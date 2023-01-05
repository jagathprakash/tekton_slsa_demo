export IMAGE_LOC=$(tkn pr describe --last -o jsonpath="{.status.results[1].value.uri}")
export IMAGE_SHA=$(tkn pr describe --last -o jsonpath="{.status.results[1].value.digest}")
export IMAGE_REF=$IMAGE_LOC@$IMAGE_SHA
gcloud artifacts docker images describe $IMAGE_REF --show-all-metadata --format json | jq -r '.provenance_summary.provenance[0].envelope.payload' | tr '\-_' '+/' | base64 -d | jq > provenance
gcloud artifacts docker images describe $IMAGE_REF --show-all-metadata --format json | jq -r '.provenance_summary.provenance[0].envelope.signatures[0].sig' | tr '\-_' '+/' | base64 -d > signature