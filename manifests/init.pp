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
# [r10k_exec]
#   Location of the r10k executable that the hook will call.
#   Used to populate the sudoers file correctly
#
# [extra_hooks]
#   Array of extra hooks required to be added
#   These are not deployed via the module
#   NOTE: Use full path for hooks
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
  $r10k_exec       = '/usr/local/bin/r10k',
  $auto_tag_serial = false,
  $r10k_update     = false,
  $extra_hooks     = undef,) {
  $git_root    = "${git_home}/repositories"
  $hook        = "${git_home}/.gitolite/hooks/common"
  $hook_concat = "${hook}/post-receive"

  if ($git_key == undef) {
    fail('missing administrators key for gitolite')
  }

  if ($auto_tag_serial == true) {
    @file { 'hook post-receive-commitnumbers':
      name   => "${hook}/post-receive-commitnumbers",
      source => "puppet:///modules/${module_name}/post-receive-commitnumbers",
      tag    => 'auto_tag_serial'
    }

    @concat::fragment { 'auto_tag_serial':
      content => "\techo \$oldrev \$newrev \$refname | ./hooks/post-receive-commitnumbers\n",
      target  => $hook_concat,
      order   => '02',
      tag     => 'post-receive',
    }
  } else {
    @file { 'remove hook post-receive-commitnumbers':
      ensure => absent,
      name   => "${hook}/post-receive-commitnumbers",
      tag    => 'auto_tag_serial'
    }
  }

  if ($r10k_update == true) {
    @file { 'r10k_env.sh':
      name    => "${hook}/r10k_env.sh",
      content => template("${module_name}/r10k_env.sh.erb"),
      tag     => 'r10k_env.sh',
      mode    => '0700'
    }

    @concat::fragment { 'r10k_env.sh':
      content => "\techo \$oldrev \$newrev \$refname | ./hooks/r10k_env.sh\n",
      target  => $hook_concat,
      order   => '03',
      tag     => 'post-receive',
    }
  } else {
    @file { 'r10k_env.sh':
      ensure => absent,
      name   => "${hook}/r10k_env.sh",
      tag    => 'r10k_env.sh',
    }
  }

  case $::operatingsystem {
    /^CentOS/ : { include epel }
    /^RedHat/ : { include epel }
    default   : { }
  }

  Package {
    ensure => installed, }

  File {
    mode  => '0755',
    owner => 'git',
    group => 'git',
  }

  case $::operatingsystem {
    /^Ubuntu/ : {
      $gitolite_pkg = 'gitolite3'
    }
    default   : {
      case $::operatingsystemmajrelease {
        '7'     : { $gitolite_pkg = 'gitolite3' }
        default : { $gitolite_pkg = 'gitolite' }
      }
    }
  }
  package { $gitolite_pkg: } ->
  user { 'git':
    ensure     => present,
    comment    => 'git user',
    managehome => true,
    home       => $git_home,
  } ->
  file { $git_home:
    ensure => directory,
    owner  => 'git',
    group  => 'git',
    mode   => '0750'
  } ->
  file { "${git_home}/install.pub":
    content => "${git_key_type} ${git_key} ${admin_user}",
    owner   => 'git',
    group   => 'git',
  } ->
  file { 'git installer':
    name    => "${git_home}/setup.sh",
    content => template("${module_name}/setup.sh.erb"),
  } ->
  exec { 'install gitolite':
    cwd     => $git_home,
    path    => '/usr/bin:/bin',
    command => "${git_home}/setup.sh",
    user    => 'git',
    creates => "${git_home}/.gitolite"
  } ->
  file { 'hook functions':
    name    => "${hook}/functions",
    content => template("${module_name}/functions.erb"),
    mode    => '0700'
  } ->
  File <| tag == 'auto_tag_serial' |> ->
  File <| tag == 'r10k_env.sh' |> ->
  file { 'gitolite sudoer file':
    name    => '/etc/sudoers.d/gitolite',
    content => template("${module_name}/sudoers.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
  }

  if ($extra_hooks != undef) {
    concat { "${hook}/post-receive":
      ensure => present,
      mode   => '0755',
    }

    gitolite::hooks { $extra_hooks: hook => $hook_concat, }

    concat::fragment { 'post-recceive header':
      target  => $hook_concat,
      content => "#!/bin/bash\n#\n. \$(dirname \$0)/functions\n\nwhile read oldrev newrev refname\ndo\n",
      order   => '01',
      tag     => 'post-receive'
    }
    Concat::Fragment <| tag == 'post-receive' |>

    concat::fragment { 'post-recceive footer':
      target  => $hook_concat,
      content => "done\n: Nothing\n",
      order   => '999',
      tag     => 'post-receive'
    }

  }

}
