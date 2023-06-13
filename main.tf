terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

resource "aws_iot_thing" "iot_demo" {
  name = "iot_demo"

  attributes = {
    First = "temperature"
  }
}

resource "aws_iot_certificate" "cert_demo" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "att" {
  principal = aws_iot_certificate.cert_demo.arn
  thing     = aws_iot_thing.iot_demo.name
}

resource "aws_iot_policy" "pubsub" {
  name = "iot_policy_topic"

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

resource "aws_iot_policy_attachment" "att" {
  policy = aws_iot_policy.pubsub.name
  target = aws_iot_certificate.cert_demo.arn
}

resource "aws_s3_bucket" "iot_bucket" {
  bucket = "iot-mqtt-s3"

  tags = {
    Name        = "iot_mqtt"
    Environment = "Dev"
  }
}


resource "aws_iam_role" "iot_role_s3" {
  name        = "iot_msg_to_s3"
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


#resource "aws_iam_role" "role" {
#  name               = "iot_role"
#  assume_role_policy = aws_iam_role.role.assume_role_policy
#}

resource "aws_iot_topic_rule" "rule" {
  name        = "iot_rule_s3_demo"
  description = "rule to send iot msg to S3"
  enabled     = true
  sql         = "SELECT *, timestamp() AS timestamps FROM 'iot/python'"
  sql_version = "2016-03-23"


  s3 {
    role_arn    = aws_iam_role.iot_s3_role.arn
    bucket_name = "iot-mqtt-s3"
    key         = "datas"
    canned_acl  = "private"
  }

}

resource "aws_sns_topic" "mytopic" {
  name = "mytopic"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iot_s3_role" {
  name               = "iot_s3_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "iam_policy_for_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.mytopic.arn]
  }
}

resource "aws_iam_role_policy" "iam_policy_for_lambda" {
  name   = "mypolicy"
  role   = aws_iam_role.iot_s3_role.id
  policy = data.aws_iam_policy_document.iam_policy_for_lambda.json
}