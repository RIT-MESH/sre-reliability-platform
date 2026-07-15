terraform { required_version = ">= 1.7.0" }

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = var.bucket_name })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms", kms_master_key_id = var.kms_key_id }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    id     = "transition-backups"
    status = "Enabled"
    filter { prefix = "backups/" }
    transition { days = 30, storage_class = "STANDARD_IA" }
    transition { days = 90, storage_class = "GLACIER" }
    expiration { days = 365 }
  }
  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter { prefix = "logs/" }
    expiration { days = 90 }
  }
  rule {
    id     = "expire-terraform-plans"
    status = "Enabled"
    filter { prefix = "tfplans/" }
    expiration { days = 14 }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    principals { type = "AWS", identifiers = ["*"] }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
