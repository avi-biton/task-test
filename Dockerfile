# Start with a minimal base image
FROM scratch

# Add Tekton resource YAMLs to the image
COPY tasks/echo-task/0.1/echo-task.yaml echo-task.yaml

# Specify the Tekton bundle label
LABEL tekton.dev/bundle=1
LABEL org.opencontainers.image.description="This is a test bundle"
