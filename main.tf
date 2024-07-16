# Variables - move to seperate file when too many
variable "resource_prefix" {
  description = "Prefix for all resources"
  default     = "dhscscdap"
}

# Providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS
provider "aws" {
  region = "eu-west-2"
}

# Datalake

resource "aws_s3_bucket" "datalake_raw" {
  bucket = format("%sdatalakeraw", var.resource_prefix)
}

resource "aws_s3_bucket" "datalake_curated" {
  bucket = format("%sdatalakecurated", var.resource_prefix)
}


resource "aws_s3_bucket" "datalake_reporting" {
  bucket = format("%sdatalakereporting", var.resource_prefix)
}

