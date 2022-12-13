export IMAGE_REF=$(tkn pr describe --last -o jsonpath="{.status.pipelineResults[2].value}")@$(tkn pr describe --last -o jsonpath="{.status.pipelineResults[3].value}")
