# terraform-google-managed-dagster
Terraform module for a Dagster deployment using Google Cloud managed services

## Overview
This module defines a production-ready Dagster deployment which is nearly fully managed/serverless, with the exception 
of a lightweight Compute Engine instance running the Dagster daemon and the Cloud SQL database. It supports multiple 
code locations. The module is quite opinionated - additional configurability may be added in the future. 

This module deploys:
- A Cloud Run webserver
- For each code location:
  - A Cloud Run service for the gRPC code server
  - A Cloud Run job for the run worker
- A Compute Engine instance for the Dagster daemon
- A Cloud SQL database and user for Dagster (the instance itself is not provisioned by this module)
- All required IAM for the above resources
  - The webserver, daemon and code servers share a primary service account with minimal permissions
  - A distinct service account is used for each run worker to facilitate fine-grained permissions between code locations
- Storage for IO and logs

## Example usage
Deploying this module requires a number of supporting resources, including prebuilt Docker images for the different
jobs/services. Refer to [dagster-gcp-demo](https://github.com/timchap/dagster-gcp-demo) for a worked example.

## Further steps
Generally speaking, the following additional components are recommended:
- Identify-Aware Proxy (IAP) for the Cloud Run webserver
- CI/CD pipelines to update the code servers and run workers when Dagster definitions are modified
- Migration support for upgrading Dagster (e.g. a Cloud Run job that runs `dagster instance migrate`)