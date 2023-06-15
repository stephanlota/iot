terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67"
    }
  }

  required_version = ">= 1.2.0"
}

# set region
provider "aws" {
  region = var.region
}

# create object
resource "aws_iot_thing" "iot_object" {
  name = "iot_object"
}

# create certificate
resource "aws_iot_certificate" "iot_cert" {
  active = true
}

# attachment iot_object with certificate
resource "aws_iot_thing_principal_attachment" "iot_cert_att" {
  principal = aws_iot_certificate.iot_cert.arn
  thing     = aws_iot_thing.iot_object.name
}


# create topic mqtt
resource "aws_iot_policy" "topic_pubsub" {
  name = "iot_object-Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "iot:Publish",
            "iot:Receive"
          ],
          "Resource" : [
            "arn:aws:iot:eu-west-1:852235686476:topic/iot/python"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "iot:Subscribe"
          ],
          "Resource" : [
            "arn:aws:iot:eu-west-1:852235686476:topicfilter/iot/python"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "iot:Connect"
          ],
          "Resource" : [
            "arn:aws:iot:eu-west-1:852235686476:client/basicPubSub"
          ]
        }
      ]
    }
  )
}

# create attachment iot_policy (topic) with iot_certificate
resource "aws_iot_policy_attachment" "aiot_policy_attachmenttt" {
  policy = aws_iot_policy.topic_pubsub.name
  target = aws_iot_certificate.iot_cert.arn
}


# create bucket S3
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "iot-mqtt-s3"

  tags = {
    Name        = "iot_mqtt"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_ownership_controls" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# set public access
resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# set S3 ACL
resource "aws_s3_bucket_acl" "s3_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3_ownership_controls,
    aws_s3_bucket_public_access_block.s3_public_access,
  ]

  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "public-read"
}


# set S3 cors
resource "aws_s3_bucket_cors_configuration" "s3_cors_config" {
  bucket = aws_s3_bucket.s3_bucket.id

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

# attachment S3 with policy
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

# Set policy
data "aws_iam_policy_document" "allow_access_from_another_account" {
  version = "2012-10-17"
  statement {
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    sid    = "PublicRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "${aws_s3_bucket.s3_bucket.arn}/*",
    ]
  }
}

# create iam role
resource "aws_iam_role" "iot_role" {
  name        = "iot_role_to_s3"
  description = "iot to access destination S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "iot.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

data "aws_iam_policy_document" "policy_doc_assume_role" {
  version = "2012-10-17"
  statement {
    sid       = "putObject"
    effect    = "Allow"
    actions   = ["s3:PutObject", ]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*", ]
  }
}

#
resource "aws_iam_policy" "rule_iam_policy" {
  name   = "rule_policy"
  policy = data.aws_iam_policy_document.policy_doc_assume_role.json
}

# create rule iot
resource "aws_iot_topic_rule" "rule" {
  name        = "iot_rule_s3"
  description = "rule to send iot msg to S3"
  enabled     = true
  sql         = "SELECT *, timestamp() AS timestamps FROM 'iot/python'"
  sql_version = "2016-03-23"


  s3 {
    role_arn    = aws_iam_role.iot_role.arn
    bucket_name = "iot-mqtt-s3"
    key         = "datas"
    canned_acl  = "private"
  }

}

# attachment role / policy
resource "aws_iam_role_policy_attachment" "S3_automation_move_objects" {
  role       = aws_iam_role.iot_role.name
  policy_arn = aws_iam_policy.rule_iam_policy.arn
}

# website configuration enabled with page html
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "page1.html"
  }
}

# copy files from www/ to bucket S3
resource "aws_s3_bucket_object" "object" {
  for_each = fileset("./www/", "**")
  bucket   = "iot-mqtt-s3"
  key      = each.value
  source   = "./www/${each.value}"
  etag     = filemd5("./www/${each.value}")
}