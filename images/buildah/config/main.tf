variable "extra_packages" {
  description = "The additional packages to install"
  type        = list(string)
  default     = []
}

module "accts" {
  source = "../../../tflib/accts"
  
  //uid    = 0
  //gid    = 0
  run-as = 0
  
}

output "config" {
  value = jsonencode({
    contents = {
      packages = concat([
        // TODO: Add any other packages here that are *always* needed.
      ], var.extra_packages)
    }
    //
    accounts = module.accts.block
    entrypoint = {
      command = "buildah"
    }
    // TODO: Add paths, envs, etc., where necessary.
    paths = [
      {
        path = "/var/tmp/storage-run-${module.accts.block.run-as}"
        type = "directory"
        uid         = module.accts.block.run-as
        gid         = module.accts.block.run-as
        permissions = 493 // 0o755 (HCL explicitly does not support octal literals)
        recursive   = true
      }
    ]
  })
}
