#!/usr/bin/env bash
set -euo pipefail

artifact_path="${1:?artifact path is required}"
artifact_name="${2:?artifact name is required}"

if [[ -z "${SIGNING_PROFILE_NAME:-}" || -z "${SIGNING_BUCKET:-}" || -z "${SIGNING_PREFIX:-}" ]]; then
  echo "SIGNING_PROFILE_NAME, SIGNING_BUCKET, and SIGNING_PREFIX must be set." >&2
  exit 1
fi

source_key="${SIGNING_PREFIX}/unsigned/${artifact_name}"
destination_prefix="${SIGNING_PREFIX}/signed/${artifact_name%.zip}"

version_id="$(
  aws s3api put-object \
    --bucket "${SIGNING_BUCKET}" \
    --key "${source_key}" \
    --body "${artifact_path}" \
    --query VersionId \
    --output text
)"

job_id="$(
  aws signer start-signing-job \
    --profile-name "${SIGNING_PROFILE_NAME}" \
    --source "s3={bucketName=${SIGNING_BUCKET},key=${source_key},version=${version_id}}" \
    --destination "s3={bucketName=${SIGNING_BUCKET},prefix=${destination_prefix}}" \
    --query jobId \
    --output text
)"

aws signer wait successful --job-id "${job_id}"

signed_key="$(
  aws signer describe-signing-job \
    --job-id "${job_id}" \
    --query 'signedObject.s3.key' \
    --output text
)"

if [[ -z "${signed_key}" || "${signed_key}" == "None" ]]; then
  echo "AWS Signer completed without returning a signed S3 object key." >&2
  exit 1
fi

echo "${signed_key}"
