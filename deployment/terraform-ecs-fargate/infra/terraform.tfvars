# Sequin Infrastructure Configuration for ap-southeast-2
# This overrides the default us-east-1 region settings

aws_region = "ap-southeast-2"
primary_availability_zone = "ap-southeast-2a"  
secondary_availability_zone = "ap-southeast-2b"

# Google sign-in (PropHero Workspace only) in front of the console. See console_oidc.tf.
console_oidc_enabled = true
