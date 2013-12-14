use strict;
use warnings;

package Dist::Zilla::UtilRole::MaybeZilla;
BEGIN {
  $Dist::Zilla::UtilRole::MaybeZilla::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::UtilRole::MaybeZilla::VERSION = '0.001000';
}

# ABSTRACT: Soft-dependency on Dist::Zilla for Utilities.


use Moose;
use Scalar::Util qw(blessed);


has zilla  => ( isa => Object =>, is => ro =>, predicate => has_zilla  => lazy_build => 1 );
has plugin => ( isa => Object =>, is => ro =>, predicate => has_plugin => lazy_build => 1 );
has logger => ( isa => Object =>, is => ro =>, lazy_build => 1, handles => [qw( log log_debug log_fatal )] );

sub logger_prefix {
  my ($self) = @_;
  my $class = blessed $self;
  return unless $class;
  $class =~ s/\ADist::Zilla::Util::/DZ:U::/msx;
  return $class;
}

sub _build_logger {
  my ($self) = @_;
  if ( $self->has_plugin and $self->plugin->can('logger') ) {
    return $self->plugin->logger->proxy(
      {
        proxy_prefix => '[' . $self->logger_prefix . '] '
      }
    );
  }
  if ( $self->has_zilla ) {
    return $self->zilla->chrome->logger->proxy(
      {
        proxy_prefix => '[' . $self->logger_prefix . '] '
      }
    );
  }
  require Log::Dispatchouli;
  return Log::Dispatchouli->new(
    ident       => $self->logger_prefix,
    to_stdout   => 1,
    log_pid     => 0,
    quiet_fatal => 'stdout',
  );
}

sub _build_zilla {
  my ($self) = @_;
  if ( $self->has_plugin and $self->plugin->can('zilla') ) {
    return $self->plugin->zilla;
  }
  return $self->log_fatal('Neither `zilla` or `plugin` were specified, and one must be specified to ->new() for this method');
}

sub _build_plugin {
  my ($self) = @_;
  return $self->log_fatal('`plugin` needs to be specificed to ->new() for this method to work');
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::UtilRole::MaybeZilla - Soft-dependency on Dist::Zilla for Utilities.

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

Dzil Is Great. But when you're writing a utility class,
loading Dist::Zilla may be not necessary, and can make testing things harder.

Namely, because to test anything that B<requires> C<Dist::Zilla>, B<requires> that you
have a valid build tree, which may be lots of unecessary work if you only need C<dzil> for
simple things like error logging.

Or perhaps, you have other resources that you only conventionally fetch from C<dzil>,
such as the C<dzil build-root>, for the sakes of making a C<Git::Wrapper>, but you're quite
happy with passing C<Git::Wrapper> instances directly for testing.

And I found myself doing quite a lot of the latter, and re-writing the same code everwhere to do it.

So, this role provides a C<zilla> attribute that is B<ONLY> required if something directly calls C<< $self->zilla >>, and it fails on invocation.

And provides a few utility methods, that will try to use C<zilla> where possible, but fallback to
a somewhat useful default if those are not available to you.

    package MyPlugin;
    use Moose;
    with 'Dist::Zilla::UtilRole::MaybeZilla';

    ...

    sub foo {
        if ( $self->has_zilla ) {
            $self->zilla->whatever
        } else {
            $slightlymessyoption
        }
    }

Additionally, it provides a few compatibility methods to make life easier, namely

    log_debug, log, log_fatal

Which will invoke the right places in C<dzil> if possible, but revert to a sensible
default if not.

=head1 ATTRIBUTES

=head2 C<zilla>

A lazy attribute, populated from C<plugin> where possible, fatalizing if not.

=head2 C<plugin>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
