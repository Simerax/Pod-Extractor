
=head1 NAME

Pod::Generator - A Module to extract Pod Documentation from Perl sourcecode.

=head1 SYNOPSIS

    use Pod::Generator;
    my $podder = Pod::Generator->new();
    $podder->root('source');
    $podder->target('docs');
    $podder->run();

=head1 DESCRIPTION

=over 2

=item B<Setters & Getters>

C<root(...)>
C<target(...)>

=cut

package Pod::Generator;

use warnings;
use strict;

use File::Path;
use File::Find;


=head2 C<new($class, $args)>

Constructor. Takes multiple Arguments

=cut


sub new {
	my ($class, $args) = @_;
	my $self = {};
	bless $self, $class;
}

=head2 C<root($self, $folder)>

Method to set/get the root Folder of the pod Extraction/Search

=cut


sub root {
	my ($self) = shift;
	$self->{'root'} = shift if (@_);
	$self->{'root'};
}

=head2 C<target($self, $folder)>

Method to set/get the target Folder of the pod Extraction/Search

=cut


sub target {
	my ($self) = shift;
	$self->{'target'} = shift if (@_);
	$self->{'target'};
}


=pod C<run($self)>

Starts the Extraction.
Will create the target Folder if necessary.

Does Return 0 on Failure and 1 on Success.
If called in List Context, it will also give you an error message as second return value

=over 4

B<Example>
my ($ok, $err) = $podder->run();
print "ERROR: $err" if (!$ok);

=back

=cut


sub run {
	my ($self) = @_;

	my $ret = sub {
		return wantarray? @_ : shift;
	};

    if (!-d $self->root()) {
        return $ret->(0, 'Root Folder does not exist');
    }


    my @files;
    my $wanted = sub {
        my $path = $File::Find::name;
        if (-f $path) {
            push @files, $path;
        }
    };

    File::Find::find($wanted, $self->root());

    if (!-d $self->target()) {
        File::Path::make_path($self->target());
    }

    $_ =~ s/\\/\//g foreach(@files);
    $_ =~ s/.+\/// foreach(@files);
    @files = map {$self->target().'/'.$_} @files;

    print "=> $_\n"foreach(@files);

    $ret->(1, '');
}


1;

