# Andrew Grimberg <agrimberg@linuxfoundation.org>
#
# === Copyright
#
# Copyright 2016 Andrew Grimberg, unless otherwise noted
#
class gitolite::params {
  $admin_user      = 'admin'
  $auto_tag_serial = false
  $git_key_type    = 'ssh-rsa'
  $git_home        = '/home/git'
  $git_root        = "${git_home}/repositories"
  $r10k_update     = false
}
