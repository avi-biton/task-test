#!/usr/bin/env bash
# Resolves a task from a given CONTEXT and from the IMAGE, both dirives from the pipelinerun
# Create a data-acceptable-bundles oci image in the task's repository, contains refs to both bundle and git reference of the task 
#
# By default both git and image references are collected, what is collected can
# be controlled by `$COLLECT` which can be set to `git` or `oci`
#
# Parameters via environment variables:
# COLLECT         - can be set to `oci` or `git` (defaults to both), what to
#                   resolve
# GIT_URL         - GIT URL contains the source code of the tasks
# CONTEXT         - A subdirectory contining a specific task  
# IMAGE           - The OCI task bundle built by the pipeline
# OUTPUT_IMAGE    - Conftest OCI bundle to write the trusted task list to


set -o errexit
set -o nounset
set -o pipefail
set -ex

mapfile -td ' ' COLLECT < <(echo -n "${COLLECT:-git oci}")

IMAGE="quay.io/avi_test/user-ns2/release-catalog/task-echo:0.2"
# GIT_URL="https://github.com/avi-biton/task-test"
# CONTEXT="task/echo/0.2"
TAG="latest"
ACCEPTABLE_BUNDLES=$(echo ${IMAGE} | awk -F'/' '{OFS="/"; $NF="data-acceptable-bundles"; print}')

# check if data-acceptable-bundles:latest artifact exists
set +e
skopeo list-tags docker://${ACCEPTABLE_BUNDLES} | jq -r '.Tags[]' | grep ${TAG} &> /dev/null
RESULT=$?
set -e
if [ $RESULT -eq 0 ]; then
  echo "Input image exists"
  ec track bundle --freshen --bundle ${IMAGE} --input oci:${ACCEPTABLE_BUNDLES}:${TAG} --output oci:${ACCEPTABLE_BUNDLES}:${TAG}
else
  echo "Input image does not exist"
  ec track bundle --freshen --bundle ${IMAGE} --output oci:${ACCEPTABLE_BUNDLES}:${TAG}
fi

# git_params=""
# oci_params=""
# for c in "${COLLECT[@]}"; do
#   case "${c}" in
#     git)
#       echo -n Adding git Task reference
#       # task_dir=${GIT_URL}//${CONTEXT}
#       task_dir=$(workspaces.source.path)/source/${CONTEXT}
#       [ ! -d ${task_dir} ] && { echo "Aborting: ${task_dir} is not a directory"; exit 1; }
#       mapfile -td '/' dirparts < <(echo "${task_dir}")
#       task_file="${task_dir}/${dirparts[-2]}.yaml"
#       [ ! -f "${task_file}" ] && { echo "Aborting: ${task_file} does not exist"; exit 1; }
#       git_params=("--git=git+${GIT_URL}/${CONTEXT}/${task_file}")
#       echo
#       echo Collected git parameters:
#       printf "%s\n" "${git_params}"
#       ;;
#     oci)
#       echo -n Adding OCI Task bundle
#       oci_params=("--bundle=${IMAGE}")
#       echo
#       echo Collected OCI parameters:
#       printf "%s\n" "${oci_params}"
#   esac
# done

# echo Running:
# PS4=''
# set -x
# ec track bundle --freshen ${git_params} ${oci_params} --output oci:${OUTPUT_IMAGE}
  
# ec track bundle --freshen --bundle ${IMAGE} --input oci:${INPUT_IMAGE} --output oci:${OUTPUT_IMAGE}