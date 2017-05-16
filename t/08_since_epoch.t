use strict;
use warnings;
use Test::More tests => 11;
use File::Spec;
use File::Path qw[rmtree];
use Cwd;
use App::SmokeBox::Mini;
use POE qw(Wheel::Run Filter::HTTP::Parser);
use Test::POE::Server::TCP;
use HTTP::Date qw( time2str );
use HTTP::Response;
use YAML::XS;
use Config;

$ENV{PERL5_SMOKEBOX_DIR} = cwd();
my $smokebox_dir = File::Spec->catdir( App::SmokeBox::Mini::_smokebox_dir(), '.smokebox' );

rmtree $smokebox_dir;
mkdir $smokebox_dir unless -d $smokebox_dir;
die "$!\n" unless -d $smokebox_dir;

open CONFIG, '> ' . File::Spec->catfile( $smokebox_dir, 'minismokebox' ) or die "$!\n";
print CONFIG <<EOF;
debug=0
indices=1
backend=Test::SmokeBox::Mini
EOF
close CONFIG;

open TIMESTAMP, '> ' . File::Spec->catfile( $smokebox_dir, 'timestamp' ) or die "$!\n";
print TIMESTAMP join( '', '[', $Config::Config{version}, $Config::Config{archname}, ']', ( time() - ( 60 * 30 ) ) ), "\n";
close TIMESTAMP;

my @data = qw(
id/A/AA/AAU/MRIM/CHECKSUMS
id/A/AA/AAU/MRIM/Net-MRIM-1.10.meta
id/A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
id/A/AD/ADAMK/CHECKSUMS
id/A/AD/ADAMK/ORLite-1.17.meta
id/A/AD/ADAMK/ORLite-1.17.readme
id/A/AD/ADAMK/ORLite-1.17.tar.gz
id/A/AD/ADAMK/Test-NeedsDisplay-1.06.meta
id/A/AD/ADAMK/Test-NeedsDisplay-1.06.readme
id/A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
id/A/AD/ADAMK/Test-NeedsDisplay-1.07.meta
id/A/AD/ADAMK/Test-NeedsDisplay-1.07.readme
id/A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
id/A/AD/ADAMK/YAML-Tiny-1.36.meta
id/A/AD/ADAMK/YAML-Tiny-1.36.readme
id/A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
);

my @tests = qw(
A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
A/AD/ADAMK/ORLite-1.17.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
);

my $yaml = YAML::XS::Dump( { recent => [ map { { path => $_, type => 'new', epoch => (time() - (60*20)) } } @data ] } );

POE::Session->create(
   package_states => [
	main => [qw(_start _timeout testd_registered testd_client_input _stdout _stderr _child_closed _oops _sig_child)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::HTTP::Parser->new( type => 'server' ),
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{url} = "http://127.0.0.1:$port/";
  return;
}

sub testd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{wheel} = POE::Wheel::Run->new(
    Program => $^X,
    ProgramArgs => [ 'bin/minismokebox', '--backend', 'Test::SmokeBox::Mini', '--url', $heap->{url} ],
    StdoutEvent => '_stdout',    # Received data from the child's STDOUT.
    StderrEvent => '_stderr',    # Received data from the child's STDERR.
    ErrorEvent  => '_oops',          # An I/O error occurred.
    CloseEvent  => '_child_closed',  # Child closed all output handles.

  );
  $kernel->sig_child( $heap->{wheel}->PID(), '_sig_child' );
  $kernel->delay( '_timeout', 240 );
  return;
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($input->as_string);
  pass('Got a recent file request');
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->header('Content-Type', 'application/octet-stream');
  $resp->header('Date', time2str(time));
  $resp->header('Server', 'Test-POE-Server-TCP/' . $Test::POE::Server::TCP::VERSION);
  $resp->header('Connection', 'close');
  $resp->content( $yaml );
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $heap->{testd}->send_to_client( $id, $resp );
  return;
}

sub _oops {
  my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
  $errstr = "remote end closed" if $operation eq "read" and !$errnum;
#  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
#  delete $_[HEAP]->{wheel};
  return;
}

sub _child_closed {
  my ($heap, $wheel_id) = @_[HEAP, ARG0];
  delete $heap->{wheel};
  return;
}

sub _stdout {
  my ($heap, $input, $wheel_id) = @_[HEAP, ARG0, ARG1];
#  print "Child process in wheel $wheel_id wrote to STDOUT: $input\n";
  if ( $input !~ /^(Submitting|Distribution)/ ) {
     diag("$input\n");
     return;
  }
  ok( ( scalar grep { $input =~ /\Q$_\E/ } @tests ), $input );
  return;
}

sub _stderr {
  my ($heap, $input, $wheel_id) = @_[HEAP, ARG0, ARG1];
#  diag("Child process in wheel $wheel_id wrote to STDERR: $input\n");
  diag($input);
  return;
}

sub _sig_child {
  $_[HEAP]->{testd}->shutdown();
  $poe_kernel->delay( '_timeout' );
  return $poe_kernel->sig_handled();
}

sub _timeout {
  $_[HEAP]->{wheel}->kill();
  return;
}
