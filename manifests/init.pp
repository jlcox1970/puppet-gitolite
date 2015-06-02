# == Class: gitolite
#
# Installs a gitolite git repository service
#
# === Parameters
# 
# [git_key]
#   administrators public ssh key for setting up the system
#
# [admin_user]
#   name for the above key
#
# [git_key_type]
#   The type of key for the administrator (defaults to ssh-rsa)
#
# [git_home]
#   root directory for the repository.
#     Defaults to the git users home direcotry (/home/git)
#
# [auto_tag_serial]
#   Adds an auto incrimental serial tag to each commit
#
# [r10k_update]
#   Run r10k after git commit to deploy both environments and modules
#   This determins what needs to be done and runs either
#   deploy module or deploy environment
#   It will run both a Puppetfile is changed
#
# === Examples
#
#  class { gitolite:
#     git_key => 'some key val',
#  }
#
# === Authors
#
# Jason Cox <j_cox@bigpond.com>
#
# === Copyright
#
# Copyright 2014 Jason Cox, unless otherwise noted.
#
class gitolite (
  $git_key         = undef,
  $admin_user      = 'admin',
  $git_key_type    = 'ssh-rsa',
  $git_home        = '/home/git',
  $auto_tag_serial = false,
  $r10k_update     = false,
){

  $git_root = "${git_home}/repositories"
  $hook     = "${git_home}/.gitolite/hooks/common"

  if ( $git_key == undef){
    fail('missing administrators key for gitolite')
  }
  if ( $auto_tag_serial == true ){
    @file {'hook post-receive-commitnumbers':
      name   => "${hook}/post-receive-commitnumbers",
      source => "puppet:///modules/${module_name}/post-receive-commitnumbers",
      tag    => 'auto_tag_serial'
    }
  } else {
    @file {'remove hook post-receive-commitnumbers':
      ensure => absent,
      name   => "${hook}/post-receive-commitnumbers",
      tag    => 'auto_tag_serial'
    }
  }
  if  ( $r10k_update == true ){
    @file {'r10k_env.sh' :
      name   => "${hook}/r10k_env.sh",
      source => "puppet///modules/${module_name}/r10k_env.sh",
      tag    => 'r10k_env.sh',
    }
  } else {
    @file {'r10k_env.sh' :
      ensure => absent,
      name   => "${hook}/r10k_env.sh",
      tag    => 'r10k_env.sh',
    }
  }
    

  include epel

  Package{
    ensure => installed,
  }
  File{
    mode    => '0700',
    owner   => 'git',
    group   => 'git',
  }

  case $::operatingsystemmajrelease {
    7 : {
    }
    default : {
      package {'gitolite' : }
    }
  }
  package {'gitolite3' : } ->
  user { 'git' :
    ensure     => present,
    comment    => 'git user',
    managehome => true,
    home       => $git_home,
  } ->
  file {"${git_home}/install.pub" :
    content => "${git_key_type} ${git_key} ${admin_user}",
    owner   => 'git',
    group   => 'git',
  } ->
  file {'git installer':
    name    => "${git_home}/setup.sh",
    content => template("${module_name}/setup.sh.erb"),
  } ->
  exec {'install gitolite':
    cwd     => $git_home,
    path    => '/usr/bin:/bin',
    command => "${git_home}/setup.sh",
    user    => 'git',
    creates => "${git_home}/.gitolite"
  } ->
  file {'hook functions':
    name    => "${hook}/functions",
    content => template("${module_name}/functions.erb"),
  } ->
  file {'hook post-receive':
    name    => "${hook}/post-receive",
    content => template("${module_name}/post-receive.erb"),
  } ->
  File <| tag == 'auto_tag_serial' |> ->
  File <| tag == 'r10k_env.sh' |>

}
