# Make a certificate for custer one.
resource "aws_acm_certificate" "one" {
  domain_name = "one.robertdebock.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "robertdebock"
  }
}

# Make a certificate for custer two.
resource "aws_acm_certificate" "two" {
  domain_name = "two.robertdebock.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "robertdebock"
  }
}

# Lookup DNS zone.
data "cloudflare_zone" "default" {
  name = "robertdebock.nl"
}

# Add validation details to the DNS zone for certificate one.
resource "cloudflare_record" "validation_one" {
  name    = tolist(aws_acm_certificate.one.domain_validation_options)[0].resource_record_name
  type    = "CNAME"
  value   = regex(".*[^.]", tolist(aws_acm_certificate.one.domain_validation_options)[0].resource_record_value)
  zone_id = data.cloudflare_zone.default.id
}

# Add validation details to the DNS zone for certificate two.
resource "cloudflare_record" "validation_two" {
  name    = tolist(aws_acm_certificate.two.domain_validation_options)[0].resource_record_name
  type    = "CNAME"
  value   = regex(".*[^.]", tolist(aws_acm_certificate.two.domain_validation_options)[0].resource_record_value)
  zone_id = data.cloudflare_zone.default.id
}

# Call the module for cluster one.
module "vault_one" {
  allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  api_addr                        = "https://one.robertdebock.nl:8200"
  certificate_arn                 = aws_acm_certificate.one.arn
  name                            = "one"
  instance_type                   = "m6g.large"
  size                            = "custom"
  source                          = "../../"
  key_filename                    = "id_rsa.pub"
  vault_type                      = "enterprise"
  vault_license                   = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JLFKFCM2PKRSGYTT2NN2E2VCFO5NEGMLMJZ5ESNCMKRCXQTKEJF2FU2TLGNHG2UTKLFVECMK2NJKTCSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJF4U4MSSNFHHURTILFUTAMKOKRNGWTCXKV4VUVCJORNEITJVLJJTC3CZKRRXUTL2LF4E4R2ZGVGVIZ3JJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIULUJVKGYVKNKRKTMTKUKU3E2RDLOVHHUZZTJZCE252PKRIXSV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJQJRKEKNKWIRCTCT3KIUYU62SBGVLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RCVORGVI3CVJVKFKNSNKRKTMTKENRQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKEKV2E22SCKVGVIVJWJVKFKNSNIRWGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S43DDMVZFKYLQIZDVOVDRIZ3GIZ3FMRZDI4JWGF4HKMZTGFJWO4CMOA4ESZ3QGJ5HQ4BQIVWFUMTDK5WEIR2FMR3EYZCJKNBE24S2HFBVQYKCNB3W4N3ZNBRGWVKMLBZHEWLUKUYEG4BRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication               = true
  tags = {
    owner = "robertdebock"
  }
}

# Call the module for cluster two.
module "vault_two" {
  allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  api_addr                        = "https://two.robertdebock.nl:8200"
  certificate_arn                 = aws_acm_certificate.two.arn
  name                            = "two"
  source                          = "../../"
  key_filename                    = "id_rsa.pub"
  vault_type                      = "enterprise"
  vault_license                   = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JLFKFCM2PKRSGYTT2NN2E2VCFO5NEGMLMJZ5ESNCMKRCXQTKEJF2FU2TLGNHG2UTKLFVECMK2NJKTCSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJF4U4MSSNFHHURTILFUTAMKOKRNGWTCXKV4VUVCJORNEITJVLJJTC3CZKRRXUTL2LF4E4R2ZGVGVIZ3JJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIULUJVKGYVKNKRKTMTKUKU3E2RDLOVHHUZZTJZCE252PKRIXSV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJQJRKEKNKWIRCTCT3KIUYU62SBGVLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RCVORGVI3CVJVKFKNSNKRKTMTKENRQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKEKV2E22SCKVGVIVJWJVKFKNSNIRWGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S43DDMVZFKYLQIZDVOVDRIZ3GIZ3FMRZDI4JWGF4HKMZTGFJWO4CMOA4ESZ3QGJ5HQ4BQIVWFUMTDK5WEIR2FMR3EYZCJKNBE24S2HFBVQYKCNB3W4N3ZNBRGWVKMLBZHEWLUKUYEG4BRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication               = true
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone for cluster one.
resource "cloudflare_record" "one" {
  name    = "one"
  type    = "CNAME"
  value   = module.vault_one.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a loadbalancer record to DNS zone for cluster two.
resource "cloudflare_record" "two" {
  name    = "two"
  type    = "CNAME"
  value   = module.vault_two.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a loadbalancer record to DNS zone for cluster one.
resource "cloudflare_record" "replication_one" {
  name    = "replication-one"
  type    = "CNAME"
  value   = module.vault_one.aws_lb_replication_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a loadbalancer record to DNS zone for cluster two.
resource "cloudflare_record" "replication_two" {
  name    = "replication-two"
  type    = "CNAME"
  value   = module.vault_two.aws_lb_replication_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# TODO: Add a aws route53 health checked record.
