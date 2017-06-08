# gitolite

Installs a gitolite git repository service, with optional hooks to r10k
for managing puppet environments.

# Parameters

#### `git_key`
   Administrators public ssh key for setting up the system. Defaoult value is `undef`.

#### `admin_user`
   Name for the admin user that the key will be associated with. Default value is `admin`.

#### `git_key_type`
   The type of key for the administrator (defaults to `ssh-rsa`)

#### `git_home`
   root directory for the repository. Defaults to the git users home direcotry (`/home/git`)

#### `auto_tag_serial`
   Adds an auto incremental serial tag to each commit. Defaults to `false`.

#### `r10k_update`
   Run r10k after git commit to deploy both environments and modules
   This determins what needs to be done and runs either deploy module or
   deploy environment. It will run both if a `Puppetfile` is changed.
   Defaults to `false`.

#### `r10k_location`
   Location of the r10k executable that the hook will call.
   Used to populate the sudoers file correctly. If the module `puppet/r10k` is installed
   it will use the value for the `$r10k_path` fact, otherwise defaults to `/bin/r10k`.

# Examples

## Simple Gitolite Managed Repositories

In order to manage repositories that have no connection to puppet, all you need to provide
is an ssh key value. Note that this uses the `ssh_key` resource type underneath, so it should
only be the key and not the key type prefix, nor the comment.

``` puppet
class { gitolite:
  git_key => 'some key val',
}
```

## Integrating r10k

If this is installed on your puppet master machine, then the repository can be
integrated with r10k. Hooks will be added to repositories so that any pushes to
these repositories result in r10k pulling the updates immediately.

``` puppet
class { gitolite:
  git_key     => 'some key val',
  r10k_update => true,
}
```

# Authors

Jason Cox <j_cox@bigpond.com>

# Copyright

Copyright 2014 - 2017 Jason Cox, unless otherwise noted.

