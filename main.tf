provider "aws" {
  region     = "us-east-1"
  profile = "ElkinH"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "bobsburger"
  role_arn = "arn:aws:iam::667259643039:role/service-role/AWSCodePipelineServiceRole-us-east-1-bobsburger"
  tags     = {}
  tags_all = {}

  artifact_store {
    location = "codepipeline-us-east-1-590394419155"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      configuration = {
        "Branch"               = "master"
        "OAuthToken"           = ""
        "Owner"                = "Elk-dev"
        "PollForSourceChanges" = "false"
        "Repo"                 = "gourmet-burgers"
      }
      input_artifacts = []
      name            = "Source"
      namespace       = "SourceVariables"
      output_artifacts = [
        "SourceArtifact",
      ]
      owner     = "ThirdParty"
      provider  = "GitHub"
      region    = "us-east-1"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "QA"

    action {
      category         = "Approval"
      configuration    = {}
      input_artifacts  = []
      name             = "QA"
      output_artifacts = []
      owner            = "AWS"
      provider         = "Manual"
      region           = "us-east-1"
      run_order        = 1
      version          = "1"
    }
  }
  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "BucketName" = "develk.com"
        "Extract"    = "true"
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      name             = "Deploy"
      namespace        = "DeployVariables"
      output_artifacts = []
      owner            = "AWS"
      provider         = "S3"
      region           = "us-east-1"
      run_order        = 1
      version          = "1"
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket              = "develk.com"
  object_lock_enabled = false
  policy = jsonencode(
    {
      Id = "PolicyForCloudFrontPrivateContent"
      Statement = [
        {
          Action = "s3:GetObject"
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = "arn:aws:cloudfront::667259643039:distribution/E2TFXIOTCFMZSC"
            }
          }
          Effect = "Allow"
          Principal = {
            Service = "cloudfront.amazonaws.com"
          }
          Resource = "arn:aws:s3:::develk.com/*"
          Sid      = "AllowCloudFrontServicePrincipal"
        },
      ]
      Version = "2008-10-17"
    }
  )
  request_payer = "BucketOwner"
  tags          = {}
  tags_all      = {}
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = "develk.com"

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = "develk.com"

  index_document {
    suffix = "index.html"
  }
}

resource "aws_cloudfront_distribution" "s3distribution" {
  aliases = [
    "develk.com",
    "www.develk.com",
  ]
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  tags                = {}
  tags_all            = {}


  wait_for_deployment = true

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = "www.develk.com.s3.us-east-1.amazonaws.com"
    trusted_key_groups     = []
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = "develk.com.s3.us-east-1.amazonaws.com"
    origin_access_control_id = "E2HV14NYGIHFX9"
    origin_id                = "www.develk.com.s3.us-east-1.amazonaws.com"
  }

  restrictions {
    geo_restriction {
      locations        = [
        "US",
      ]
      restriction_type = "whitelist"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:667259643039:certificate/ad121fd0-44a5-4420-bddc-151de46d0b0d"
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}
resource "aws_route53_record" "www" {
  name    = "develk.com"
  type    = "A"
  zone_id = "Z069698134XUC0JQKN3FU"

  alias {
    evaluate_target_health = false
    name                   = "d1ks8uep0121gl.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "ww" {
  name    = "www.develk.com"
  type    = "A"
  zone_id = "Z069698134XUC0JQKN3FU"

  alias {
    evaluate_target_health = false
    name                   = "d1ks8uep0121gl.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "cname1" {
  name = "develk.com"
  records = [
    "ns-1057.awsdns-04.org.",
    "ns-1599.awsdns-07.co.uk.",
    "ns-447.awsdns-55.com.",
    "ns-650.awsdns-17.net.",
  ]
  ttl     = 172800
  type    = "NS"
  zone_id = "Z069698134XUC0JQKN3FU"
}

resource "aws_cloudwatch_metric_alarm" "site_health" {
actions_enabled           = true
    alarm_actions             = [
        "arn:aws:sns:us-east-1:667259643039:WebsiteOffline",
    ]
    alarm_name                = "www-develk-com-awsroute53-7455b0c5-a0a2-40a5-abc1-ce0b1e7909f7-Low-HealthCheckStatus"
    comparison_operator       = "LessThanThreshold"
    dimensions                = {
        "HealthCheckId" = "7455b0c5-a0a2-40a5-abc1-ce0b1e7909f7"
    }
    evaluation_periods        = 1
    insufficient_data_actions = []
    metric_name               = "HealthCheckStatus"
    namespace                 = "AWS/Route53"
    ok_actions                = []
    period                    = 60
    statistic                 = "Minimum"
    tags                      = {}
    tags_all                  = {}
    threshold                 = 1
    treat_missing_data        = "missing"
}

resource "aws_cloudwatch_metric_alarm" "houseErrors" {
    actions_enabled           = true
    alarm_actions             = [
        "arn:aws:sns:us-east-1:667259643039:HueristicEinstein",
    ]
    alarm_description         = "The website is currently experiencing a high number of 500 errors. Check to make sure the website is working properly."
    alarm_name                = "Too_Many_500_errors"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    datapoints_to_alarm       = 1
    dimensions                = {
        "DistributionId" = "E2TFXIOTCFMZSC"
        "Region"         = "Global"
    }
    evaluation_periods        = 1
    insufficient_data_actions = []
    metric_name               = "5xxErrorRate"
    namespace                 = "AWS/CloudFront"
    ok_actions                = []
    period                    = 300
    statistic                 = "Average"
    tags                      = {}
    tags_all                  = {}
    threshold                 = 5
    treat_missing_data        = "missing"
}

resource "aws_cloudwatch_metric_alarm" "clientErrors" {
actions_enabled           = true
    alarm_actions             = [
        "arn:aws:sns:us-east-1:667259643039:HueristicEinstein",
    ]
    alarm_description         = "There are currently a large number of 400 errors linked to your web server."
    alarm_name                = "Too_Many_400_Errors"
    comparison_operator       = "GreaterThanThreshold"
    datapoints_to_alarm       = 1
    dimensions                = {
        "DistributionId" = "E2TFXIOTCFMZSC"
        "Region"         = "Global"
    }
    evaluation_periods        = 1
    insufficient_data_actions = []
    metric_name               = "4xxErrorRate"
    namespace                 = "AWS/CloudFront"
    ok_actions                = []
    period                    = 300
    statistic                 = "Average"
    tags                      = {}
    tags_all                  = {}
    threshold                 = 50
    treat_missing_data        = "missing"
}

resource "aws_cloudwatch_metric_alarm" "bill" {
actions_enabled           = true
    alarm_actions             = [
        "arn:aws:sns:us-east-1:667259643039:HueristicEinstein",
    ]
    alarm_description         = "Your architecture is currently running at least $1 per day."
    alarm_name                = "Exceeded_1_Dollar_Per_Day"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    datapoints_to_alarm       = 1
    dimensions                = {
        "Currency" = "USD"
    }
    evaluation_periods        = 1
    insufficient_data_actions = []
    metric_name               = "EstimatedCharges"
    namespace                 = "AWS/Billing"
    ok_actions                = []
    period                    = 86400
    statistic                 = "Maximum"
    tags                      = {}
    tags_all                  = {}
    threshold                 = 1
    treat_missing_data        = "missing"
}

resource "aws_acm_certificate" "cert" {
    domain_name               = "develk.com"
    key_algorithm             = "RSA_2048"
    subject_alternative_names = [
        "develk.com",
        "www.develk.com",
    ]
    tags                      = {}
    tags_all                  = {}
    validation_method         = "DNS"

    options {
        certificate_transparency_logging_preference = "ENABLED"
    }
}

resource "aws_sns_topic" "user_updates" {
application_success_feedback_sample_rate = 0
    content_based_deduplication              = false
    fifo_topic                               = false
    firehose_success_feedback_sample_rate    = 0
    http_success_feedback_sample_rate        = 0
    lambda_success_feedback_sample_rate      = 0
    name                                     = "HueristicEinstein"
    policy                                   = jsonencode(
        {
            Id        = "__default_policy_ID"
            Statement = [
                {
                    Action    = [
                        "SNS:Publish",
                        "SNS:RemovePermission",
                        "SNS:SetTopicAttributes",
                        "SNS:DeleteTopic",
                        "SNS:ListSubscriptionsByTopic",
                        "SNS:GetTopicAttributes",
                        "SNS:AddPermission",
                        "SNS:Subscribe",
                    ]
                    Condition = {
                        StringEquals = {
                            "AWS:SourceOwner" = "667259643039"
                        }
                    }
                    Effect    = "Allow"
                    Principal = {
                        AWS = "*"
                    }
                    Resource  = "arn:aws:sns:us-east-1:667259643039:HueristicEinstein"
                    Sid       = "__default_statement_ID"
                },
                {
                    Action    = "SNS:Publish"
                    Effect    = "Allow"
                    Principal = {
                        AWS = "*"
                    }
                    Resource  = "arn:aws:sns:us-east-1:667259643039:HueristicEinstein"
                    Sid       = "__console_pub_0"
                },
                {
                    Action    = "SNS:Subscribe"
                    Effect    = "Allow"
                    Principal = {
                        AWS = "*"
                    }
                    Resource  = "arn:aws:sns:us-east-1:667259643039:HueristicEinstein"
                    Sid       = "__console_sub_0"
                },
                {
                    Action    = "sns:Publish"
                    Effect    = "Allow"
                    Principal = {
                        Service = "events.amazonaws.com"
                    }
                    Resource  = "arn:aws:sns:us-east-1:667259643039:HueristicEinstein"
                    Sid       = "AWSEvents_Pipeline_Failure_Id28260783-1f12-4e3c-b9ac-b3212ab8119b"
                },
            ]
            Version   = "2008-10-17"
        }
    )
    sqs_success_feedback_sample_rate         = 0
    tags                                     = {}
    tags_all                                 = {}
    tracing_config                           = "PassThrough"
}

resource "aws_sns_topic" "site_down" {
    application_success_feedback_sample_rate = 0
    content_based_deduplication              = false
    fifo_topic                               = false
    firehose_success_feedback_sample_rate    = 0
    http_success_feedback_sample_rate        = 0
    lambda_success_feedback_sample_rate      = 0
    name                                     = "Website_Offline_TEST"
    policy                                   = jsonencode(
        {
            Id        = "__default_policy_ID"
            Statement = [
                {
                    Action    = [
                        "SNS:GetTopicAttributes",
                        "SNS:SetTopicAttributes",
                        "SNS:AddPermission",
                        "SNS:RemovePermission",
                        "SNS:DeleteTopic",
                        "SNS:Subscribe",
                        "SNS:ListSubscriptionsByTopic",
                        "SNS:Publish",
                    ]
                    Condition = {
                        StringEquals = {
                            "AWS:SourceOwner" = "667259643039"
                        }
                    }
                    Effect    = "Allow"
                    Principal = {
                        AWS = "*"
                    }
                    Resource  = "arn:aws:sns:us-east-1:667259643039:Website_Offline_TEST"
                    Sid       = "__default_statement_ID"
                },
            ]
            Version   = "2008-10-17"
        }
    )
    sqs_success_feedback_sample_rate         = 0
    tags                                     = {}
    tags_all                                 = {}
}

resource "aws_sns_topic" "siteTest" {
    application_success_feedback_sample_rate = 0
    content_based_deduplication              = false
    fifo_topic                               = false
    firehose_success_feedback_sample_rate    = 0
    http_success_feedback_sample_rate        = 0
    lambda_success_feedback_sample_rate      = 0
    name                                     = "TerraformDummy"
    policy                                   = jsonencode(
        {
            Id        = "__default_policy_ID"
            Statement = [
                {
                    Action    = [
                        "SNS:GetTopicAttributes",
                        "SNS:SetTopicAttributes",
                        "SNS:AddPermission",
                        "SNS:RemovePermission",
                        "SNS:DeleteTopic",
                        "SNS:Subscribe",
                        "SNS:ListSubscriptionsByTopic",
                        "SNS:Publish",
                    ]
                    Condition = {
                        StringEquals = {
                            "AWS:SourceOwner" = "667259643039"
                        }
                    }
                    Effect    = "Allow"
                    Principal = {
                        AWS = "*"
                    }
                    Resource  = "arn:aws:sns:us-east-1:667259643039:Website_Offline_TEST"
                    Sid       = "__default_statement_ID"
                },
            ]
            Version   = "2008-10-17"
        }
    )
    sqs_success_feedback_sample_rate         = 0
    tags                                     = {}
    tags_all                                 = {}
}