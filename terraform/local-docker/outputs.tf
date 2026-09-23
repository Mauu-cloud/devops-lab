output "urls" {
  value = {
    dev = module.app_dev.url
    qa  = module.app_qa.url
  }
}
