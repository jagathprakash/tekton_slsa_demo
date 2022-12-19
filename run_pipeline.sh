#!/bin/sh
set -e

dir=$(dirname $0)
. "${dir}"/env.sh

pipelinerun=$(mktemp)
envsubst < "${dir}/pipeline_run.yaml" > "${pipelinerun}"
kubectl create --filename "${pipelinerun}"
rm -rf "${pipelinerun}"

# Wait for completion!
tkn pr logs --last -f
