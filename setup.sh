# install pipelines
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# install chains
kubectl apply --filename https://storage.googleapis.com/tekton-releases/chains/previous/v0.11.0/release.yaml
# install tasks from hub
tkn hub install task git-clone
tkn hub install task kaniko