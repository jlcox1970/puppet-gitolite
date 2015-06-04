#  This define is to build file fragements for the post-recieve hook
#
define gitolite::hooks (
  $hook,
  $hook_file  = $name,
){
  @concat::fragment { "Gitolite hook ${hook_file} is being added" :
    content => "\techo \$oldrev \$newrev \$refname | ${hook_file}\n",
    target  => $hook,
    order   => '10',
    tag     => 'post-receive',
  }
}
