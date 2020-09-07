
resource "aws_s3_bucket" "balrog-ui-ghosterydev-com" {
  bucket = "balrog-ui.ghosterydev.com"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# resource "aws_route53_record" "balrogui-ghosterydev-com" {
#   zone_id = local.dns_zone_id
#   name    = local.dns_name_ui
#   type    = "CNAME"
#   records = [ aws_s3_bucket.balrog-ui-ghosterydev-com.website_endpoint ]
#   ttl     = "300"
# }
