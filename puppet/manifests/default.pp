node 'default' {
  class { 'apache':
    server_tokens => 'minimal',
  }

  file { "${apache::docroot}/index.html":
    content => '<html><body><h1>Hello World</h1></body></html>',
    owner   => $apache::user,
    group   => $apache::group,
    mode    => '0444',
    require => Class['apache'],
  }
}
