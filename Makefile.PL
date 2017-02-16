BEGIN {
    ### chdir to the makefile.pl dir
    use FindBin;
    use lib $FindBin::Bin;
}
use strict;
use inc::Module::Install;
name 'minismokebox';
author 'Chris Williams <chris@bingosnet.co.uk>';
version_from 'lib/App/SmokeBox/Mini.pm';
abstract_from 'bin/minismokebox';
install_script 'bin/minismokebox';
license 'perl';
auto_license holder => 'Chris Williams';
perl_version '5.006';
build_requires 'Test::More' => 0.47;
build_requires 'Test::POE::Server::TCP' => 0.12;
build_requires 'POE::Filter::HTTP::Parser' => 1.06;
build_requires 'HTTP::Response' => 0;
build_requires 'HTTP::Date' => 0;
requires 'unless' => 0.02;
requires 'Config::Tiny' => 2.12;
requires 'File::Spec' => 0;
requires 'File::Path' => 0;
requires 'Pod::Usage' => '1.00';
requires 'Time::Duration' => 1.06;
requires 'POE' => 1.005;
requires 'POE::Component::SmokeBox' => 0.36;
requires 'POE::Component::SmokeBox::Recent' => 1.30;
requires 'POE::Component::SmokeBox::Dists' => 1.04;
requires 'App::SmokeBox::PerlVersion' => 0.16;
requires 'Module::Pluggable' => 0;
requires 'Module::Load' => 0;
if ( can_cc() ) {
  requires 'POE::XS::Queue::Array' => 0.005;
  if ( $^O eq 'linux' ) {
    requires 'POE::XS::Loop::EPoll' => 1.001;
  }
  # Problem with POE::XS::Loop::Poll on MacOSX use Event
  # [rt.cpan.org #68608]
  elsif ( $^O =~ /^(MSWin32|darwin)$/ ) {
    requires 'Event' => 0;
    requires 'POE::Loop::Event' => 0;
  }
  else {
    requires 'POE::XS::Loop::Poll' => 1.000;
  }
}
clean_files '.smokebox jobs.txt';
auto_provides;
githubmeta;
makemaker_args(dist => { PREOP => "$^X ./tools/git-log.pl > ./Changes" });
WriteAll();
