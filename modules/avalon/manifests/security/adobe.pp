class avalon::security::adobe {
  include avalon::security
  
  staging::file { "ams-avalon.tar.gz":
    source  => "puppet:///modules/avalon/ams/ams-avalon.tar.gz",
    subdir  => ams,
  }

  staging::extract { "ams-avalon.tar.gz":
    target  => '/opt/adobe/ams/applications/',
    subdir  => ams,
    creates => '/usr/local/red5/webapps/avalon',
    require => [Staging::File["ams-avalon.tar.gz"]]
  }

  service { "ams": 
    ensure => running,
    enable => true,
  }

  exec { "add Avalon config to ams.ini":
    command => "/usr/bin/printf \"\n\nAVALON.AUTH_URL = ${avalon::info::avalon_url}/authorize\nAVALON.STREAM_PATH = ${avalon::info::root_dir}/rtmp_streams\n\" >> ams.ini",
    cwd     => '/opt/adobe/ams/conf',
    unless  => "/bin/grep '${avalon::info::avalon_url}/authorize' ams.ini",
    notify  => Service['ams']
  }

  file { '/opt/adobe/ams/Apache2.2/conf/avalon.conf':
    content => template('avalon/security/avalon_httpd_ams.conf.erb'),
    mode    => 0755,
    notify  => Service['ams']
  }

  exec { "include avalon.conf in httpd.conf":
    command => "/usr/bin/printf \"\n\nInclude conf/avalon.conf\n\" >> httpd.conf",
    cwd     => '/opt/adobe/ams/Apache2.2/conf/',
    unless  => "/bin/grep avalon.conf httpd.conf",
    require => File['/opt/adobe/ams/Apache2.2/conf/avalon.conf'],
    notify  => Service['ams']
  }
}