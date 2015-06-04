define gitolite::hooks (
  $hook_file  = $name,
  $hook ,
){
  @concat::fragment { "Gitolite hook ${hook_file} is being added" :
      content => "\techo \$oldrev \$newrev \$refname | ${hook_file}\n",
      target  => "${hook}",
      order   => '10',
      tag     => 'post-receive',
  }
}
