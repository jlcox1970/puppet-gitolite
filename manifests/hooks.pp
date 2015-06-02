define gitolite::hooks (
  $hook  = $::name,
  $target = $::target_name,
  $tag    = $::tag_name
){
  @concat::fragment { $hook :
      content => "${hook}",
      target  => "${target_name}",
      order   => '03',
      tag     => "${tag}",
  
}