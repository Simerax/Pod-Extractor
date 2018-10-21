package Pod::Generator::Helper;

use warnings;
use strict;
use File::Path;

use vars qw(@ISA @EXPORT_OK);


BEGIN {
	require Exporter;
	@ISA = qw(Exporter);

	@EXPORT_OK = qw(
	  ret
	  get_basename
	  read_file
	  write_file
	  create_dir
	);
}

=head1 NAME

Pod::Generator::Helper - Helper Utilities for Pod::Generator - There is no reason to use this package standalone

=head1 SYNOPSIS

    use Pod::Generator::Helper qw(ret);

=head1 DESCRIPTION

This Package is used by C<Pod::Generator> for all kinds of tasks which are not really connected to it. Such as reading/writing or creating files.
B<If you want to Extract Pod Documents from Perl Sourcecode you should use >C<Pod::Generator>B< and not this Package here!>

=head2 Functions

=head3 C<ret(...)>

Basically just checks if called in list context or not. Returns C<@_> in listcontext C<shift> otherwise
This is to do the following:

    sub A {
        my ($ok, $err);
        # ... do something with $ok and $err

        ret($ok, $err);
    }

    if (A()) { # A returns in scalar context

    }
    my ($ok, $err) = A(); # a returns in list context

    # This is just to write
    return ret(1, '');
    # instead of
    return wantarray? (1, ''): 1;

    # Yes it's not clean and could be done much better. But its enough for now.

=cut


sub ret {
	return wantarray? @_ : shift;
}


=head3 C<get_basename($name)>

Removes everything behind the last dot '.' in a string (including the dot)

    my $new_name = get_basename('Abc.txt');
    print $new_name; # Abc

=cut


sub get_basename {
	my ($name) = @_;
	$name =~ s/\.[^\.]*$//;
	$name;
}


=head3 C<read_file($file)>

Opens the file C<$file> and reads its C<$content>

    my ($ok, $err, $content) = read_file('B.pm');
    if ($ok) {
    	print "=> $_\n" foreach(@$content);
    }

=cut


sub read_file {
	my ($file) = @_;

	my @content;
	my $fh;
	open($fh, '<', $file) || return ret(0, "Error while reading file '$file'. Reason: $!", undef, undef);

	while(<$fh>) {
		push @content, $_;
	}
	close($fh);
	return ret(1, '', \@content);
}


=head3 C<write_file($file, $content)>

Writes given C<$content> to C<$file>

    my ($ok, $err) = write_file('A.pm', 'ABC');
    if (!$ok) {
    	print "ERROR: $err\n";
    }

=cut


sub write_file {
	my ($file, $content) = @_;

	my $fh;
	return ret(0, $!) unless open($fh, '>', $file);
	print $fh "$content";
	close($fh);

	ret(1, 'No Error');
}

=head3 C<create_dir($dir)>

Creates given $dir with the Help of L<File::Path>

    my ($ok, $err) = create_dir('test');
    if (!$ok) {
    	print "ERROR: $err\n";
    }

=cut


sub create_dir {
	my ($dir) = @_;

	return ret(1, 'Directory already exists') if -d $dir;

	my ($raw_err, $err_string);
	File::Path::make_path($dir, { error => \$raw_err });

	foreach my $diag (@$raw_err) {
		my ($object, $msg) = %$diag;
		$err_string .= $object eq '' ? "General Error: $msg\n" : "Problem on $object - $msg\n";
	}

	if($err_string) {
		return ret(0, $err_string);
	} else {
		return ret(1, 'No Error');
	}
}


1;