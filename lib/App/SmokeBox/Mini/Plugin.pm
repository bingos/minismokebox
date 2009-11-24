package App::SmokeBox::Mini::Plugin;

use strict;
use warnings;

our $VERSION = '0.21_01';

qq[Smokin' plugins];

__END__

=head1 NAME

App::SmokeBox::Mini::Plugin - minismokebox plugins

=head1 DESCRIPTION

This document describes the App::SmokeBox::Mini::Plugin system for 
L<App::SmokeBox::Mini> and L<minismokebox>.

Plugins are a mechanism for providing additional functionality to
L<App::SmokeBox::Mini> and L<minismokebox>.

It is assumed that plugins will be L<POE> based and consist of at least one
L<POE::Session>.

=head1 INITIALISATION

The plugin constructor is C<init>. L<App::SmokeBox::Mini> uses 
L<Module::Pluggable> to find plugins beneath the App::SmokeBox::Mini::Plugin
namespace and will attempt to call C<init> on each plugin class that it finds.

C<init> will be called with one parameter, a hashref that contains keys for each
section of the L<minismokebox> configuration file, (which utilises L<Config::Tiny>).

The role of the plugin is to determine if an appropriate section exists for its
own configuration.

If no appropriate configuration exists, then C<init> must return C<undef>.

If appropriate configuration does exist, then the plugin may start a L<POE::Session>.

L<App::SmokeBox::Mini> will watch for a C<_child> event indicating that it has gained
a plugin child session. It will detach this child after making a note of the child's 
session ID which it will use to send the following events.

=head1 EVENTS

=over

=item C<sbox_smoke>

=item C<sbox_stop>

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

=cut
