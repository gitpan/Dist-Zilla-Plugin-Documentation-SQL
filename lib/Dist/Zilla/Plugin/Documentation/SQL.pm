package Dist::Zilla::Plugin::Documentation::SQL;

# ABSTRACT: Create a file gathering all =sql commands


use strict;
use warnings;

use Path::Class;
use Pod::Elemental;
use Pod::Elemental::Element::Nested;
use Moose;

with qw/
  Dist::Zilla::Role::FileInjector
  Dist::Zilla::Role::FileMunger
  Dist::Zilla::Role::Plugin
  /;

with 'Dist::Zilla::Role::FileFinderUser' =>
  { default_finders => [ ':InstallModules', ], };


sub documentation_dir {
    my ($self) = @_;
    ( my $package = $self->zilla->name ) =~ s@-@/@g;
    my $package_dir       = dir("lib/$package");
    my $documentation_dir = $package_dir->subdir('Documentation');
    $documentation_dir->mkpath;
    return $documentation_dir;
}


sub documentation_file {
    my ($self) = @_;
    my $documentation_file = $self->documentation_dir->file('SQL.pod');
    return $documentation_file . "";
}


sub munge_files {
    my ($self) = @_;
    my @sqls =
      map {

        # Retrieve only a command from POD content and only sql ones
        grep {
            if (    $_->isa('Pod::Elemental::Element::Generic::Command')
                and $_->command eq 'sql' )
            {
                $_;
            }
          }

          # Retrieve Pod elements from the file contained in the package
          @{ Pod::Elemental->read_file( $_->name )->children }
      } @{ $self->found_files };

    my $document = Pod::Elemental::Document->new;
    my $nested   = Pod::Elemental::Element::Nested->new(
        command => 'head1',
        content => 'SQL',
    );
    $document->children( [$nested] );

    $nested->children(
        [
            map {
                Pod::Elemental::Element::Pod5::Ordinary->new(
                    content => $_->content, )
              } @sqls
        ]
    );

    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            name    => $self->documentation_file,
            content => $document->as_pod_string,
        )
    );
    return;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Documentation::SQL - Create a file gathering all =sql commands

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Put in your dist.ini file

  name = Sample-Package
  author = E. Xavier Ample <example@example.org>
  license = GPL_3
  copyright_holder = E. Xavier Ample
  copyright_year = 2014
  version = 0.42

  [Documentation::SQL]

Then, dist will automatically search all your package files for documentation that looks like

  =sql SELECT * FROM table

  =cut

And will put all of them in a single file, located at (for the example)

  lib/Sample/Package/Documentation/SQL.pod

=head1 METHODS

=head2 documentation_dir

This method returns your main_module documentation linked dir, to put
generated documentation in it.

  $documentation_dir = $self->documentation_dir;

=head2 documentation_file

Retrieve the location where to put the file, and give the filename.

=head2 munge_files

A L<Dist::Zilla::Role::FileMunger|FileMunger> overwriting in order to have
direct access to every content that are included in a =sql command.

This method is called directly by B<dist>.

=head1 AUTHOR

Armand Leclercq <armand.leclercq@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Armand Leclercq.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

