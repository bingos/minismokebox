package POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini;

#ABSTRACT: a backend to App::SmokeBox::Mini.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
	check => [ '-e', 1 ],
	index => [ '-e', 1 ],
	smoke => [ '-e', '$|=1; if ( $ENV{PERL5LIB} ) { require App::SmokeBox::Mini::Plugin::Test; } else { my $module = shift; print $module, qq{\n}; } sleep 5; exit 0;' ],
  };
  return;
}

1;

=pod

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini is a L<POE::Component::SmokeBox::Backend> plugin used during the
L<App::SmokeBox::Mini> tests.

It contains no moving parts.

=head1 SEE ALSO

L<POE::Component::SmokeBox::Backend>

=cut


