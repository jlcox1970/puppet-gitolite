define gitolite::hooks (
  $hook_file  = $::name,
  $hook ,
){
  @concat::fragment { $hook :
      content => "\techo \$oldrev \$newrev \$refname | ${hook_file}",
      target  => "${hook}/post-recieve",
      order   => '03',
      tag     => 'post-recieve',
  }
}