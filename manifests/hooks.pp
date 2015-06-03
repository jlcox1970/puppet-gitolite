define gitolite::hooks (
  $hook  = $::name,
  $target = $::target_name,
  $tag    = $::tag_name
){
  @concat::fragment { $hook :
      content => "\techo \$oldrev \$newrev \$refname | ${hook}",
      target  => "${target_name}",
      order   => '03',
      tag     => "${tag}",
  }
}