

package Pod::Generator;

our $VERSION = '0.50';

use warnings;
use strict;

use File::Basename;
use File::Path;
use File::Find::Rule;
use Carp qw (carp croak);

my $ret = sub {
	return wantarray? @_ : shift;
};


sub new {
	my ($class, $args) = @_;
	my $self = {};
	bless $self, $class;

	$self->root($args->{'root'}) if (defined $args->{'root'});
	$self->parser($args->{'parser'}) if (defined $args->{'parser'});
	$self->target($args->{'target'}) if (defined $args->{'target'});
	$self->overwrite($args->{'overwrite'}) if (defined $args->{'overwrite'});

	return $self;
}


sub root {
	my $self = shift;
	$self->{'root'} = shift if (@_);
	$self->{'root'};
}


sub target {
	my $self = shift;
	my $target = shift;
	if ($target) {
		$self->{'target'} = $target =~ /\/$/ ? $target : $target . '/';
	}
	$self->{'target'};
}


sub overwrite {
	my $self = shift;
	if (@_) {
		$self->{'overwrite'} = shift;
	}
	$self->{'overwrite'} = 0 unless (defined $self->{'overwrite'});
	$self->{'overwrite'};
}


sub parser {
	my ($self, $parser) = @_;

	if ($parser) {
		if (ref($parser) eq 'CODE') {
			$self->{'parser'} = $parser;
		} else {
			carp "Parser is not a codereference! Falling back to default";
			$self->{'parser'} = $self->_default_parser();
		}
	} else {
		if (!$self->{'parser'}) {
			$self->{'parser'} = $self->_default_parser();
		}
	}

	$self->{'parser'};
}


sub _default_parser {
	my ($self) = @_;

	sub {
		my ($file) = @_;
		my $parsed;
		use Pod::Simple::HTML;
		my $p = Pod::Simple::HTML->new();
		$p->output_string(\$parsed);
		$p->parse_file($file);

		return ($parsed, '.html');
	};
}


sub run {
	my ($self) = @_;

	my ($ok, $err, $files) = $self->_find_files();
	if (!$ok) {
		return $ret->(0, $err);
	}

	$self->target('./docs') unless (defined $self->target());

	foreach(@$files) {
		my ($content, $filetype) = $self->parser()->($_);
		$filetype = '' unless (defined $filetype);

		my ($name, $path, $suffix) = fileparse($_);
		$name = _get_basename($name) unless $suffix; # fileparse doesnt really get the right basname (suffix is still present)

		my $root = $self->root();
		$path =~ s/^\Q$root\E//;

		my $target_dir = $self->target().$path;
		my $target_file = $target_dir.'/'.$name.$filetype;

		next if (-f $target_file && !$self->overwrite());

		if (!-d $target_dir) {
			my ($ok, $err) = $self->_create_dir($target_dir) unless (-d $target_dir);
			if (!$ok) {
				carp $err;
				next;
			}
		}

		my ($ok, $err) = $self->_write_file($target_file, $content);
		if (!$ok) {
			carp $err;
			next;
		}

	}
	$ret->(1, '');
}


# _find_files
#	returns a list of all files found in $self->root()
#
# Returns 0 on failure and 1 on success
# in list context it also gives you an error message and the files it found.
# So basically you should never call it in scalar context ;)
#
#	my ($ok, $err, $files) = $self->_find_files();
#	if ($ok) {
#		print "FOUND: $_\n" foreach(@$files);
#	}
#
#
sub _find_files {
	my ($self) = @_;

	my ($ok, $err, $type) = $self->_check_root();
	return $ret->(0, $err, undef) if (!$ok);

	my $finder = File::Find::Rule->new();
	$finder->file()->name('*.pm', '*.pl')->canonpath();

	my @files;
	if ($type eq '') {
		@files = $finder->in($self->root());
	}
	elsif ($type eq 'ARRAY') {
		@files = $finder->in(@{$self->root()});
	} else { # since we do _check_root() we should never get here but oh well you never know
		croak "Type '$type' not supported as root folder!";
	}
	return $ret->(1, '', \@files);
}

# _create_dir
#   Create given $dir
#
# Returns 0 on Failure and 1 on Success
# In listcontext it also returns an errorstring
#
#   my ($ok, $err) = $self->_create_dir('test');
#
sub _create_dir {
	my ($self, $dir) = @_;

	return $ret->(1, 'Directory already exists') if -d $dir;

	my ($raw_err, $err_string);
	File::Path::make_path($dir, { error => \$raw_err });

	foreach my $diag (@$raw_err) {
		my ($object, $msg) = %$diag;
		$err_string .= $object eq '' ? "General Error: $msg\n" : "Problem on $object - $msg\n";
	}

	if($err_string) {
		return $ret->(0, $err_string);
	} else {
		return $ret->(1, 'No Error');
	}
}


sub _get_basename {
	my ($name) = @_;
	$name =~ s/\.[^\.]*$//;
	$name;
}


sub _write_file {
	my ($self, $file, $content) = @_;

	my $fh;
	return $ret->(0, $!) unless open($fh, '>', $file);
	print $fh "$content";
	close($fh);

	$ret->(1, 'No Error');
}


# _check_root
#	Checks the type of $self->root()
#
# Returns 0 on failure and 1 on success
# in list context it also gives you an error message and the type of root
#
# 	my ($ok, $err, $type) = $self->_check_root();
# 	if ($ok && $type eq 'ARRAY') {
#		print "root is an array reference!";
#	} 
#
sub _check_root {
	my ($self) = @_;

	my $check = sub {
		my $f = shift;
		if (!-d $f) {
			carp "Root Folder '$f' does not exist!";
		}
	};

	return $ret->(0, 'Root not specified') unless defined $self->root();

	my $type = ref($self->root());

	if ($type eq '') {
		$check->($self->root());
		return $ret->(1, '', $type);
	}elsif ($type eq 'ARRAY') {
		$check->($_) foreach(@{$self->root()});
		return $ret->(1, '', $type);
	} else {
		my $err = "Type $type is not supported as 'root' directory!";
		carp $err;
		return $ret->(0, $err, undef);
	}
}


=head1 NAME

Pod::Generator - A Module to extract Pod Documentation from Perl sourcecode.

=head1 VERSION

Version 0.50

=head1 SYNOPSIS

    use Pod::Generator;
    my $podder = Pod::Generator->new({
        root => 'lib',
        target => 'docs',
    });
    my ($ok, $err) = $podder->run();
    if (!$ok) {
        print "ERROR: $err\n";
    }

=head1 DESCRIPTION

This Module is for extracting Pod Documentation from Perl Sourcecode recursively and converting it into the desired Format.
You give it a entry point on your filesystem and it will extract and parse all POD from every *.pm and *.pl file and dump them in your specific target folder

=head2 Functions


=head3 C<new($class, $args)>

Function to initalize a C<Pod::Generator> instance.
C<$args> is a hash reference. You can specify every Attribute right here or use the appropriate setter afterwards.

    my $generator = Pod::Generator->new({
        root => './lib',    # the directory in which the search should begin
		# root => [qw( libA libB )], # root can also be an array reference
        target => 'docs',   # the directory in which the parsed Documents should be stored
        overwrite => 1,     # Overwrite file in 'target' if it already exist. Will default to 0 if not given
        parser => sub {     # give it a custom Parser. You dont need to do this, the default parsing is done with Pod::Simple::HTML
            my ($file) = @_;

            # ... open $file and parse it the way you want

            return ($parsed, '.html'); # Return the parsed content and an optional suffix the File should get
        },
    });


=head3 C<run($self)>

Starts the Extraction.
Will create the target Folder if necessary.
Will set C<target> to './docs' if there is no specified target.

Does Return 0 on Failure and 1 on Success.
If called in List Context, it will also give you an error message as second return value.

    my ($ok, $err) = $podder->run();
    print "ERROR: $err" if (!$ok);

=head3 C<root($self, $folder)>

Method to set/get the root Folder of the pod Extraction.

=head3 C<target($self, $folder)>

Method to set/get the target Folder of the pod Extraction.
Appends '/' to the target in case it doesnt have it already

=head3 C<overwrite($self, $bool)>

Method to set/get the overwrite Attribute.
This will cause the Extraction to overwrite files in C<target> if they exist.
Default is 0 (false).

Every true Value is considered C<overwrite == true>

=head3 C<parser($self, $parser)>

Method to set/get the Parser for the Pod Extraction.
Expects a Code Reference.

This Function gives you C<$file> which is the filepath of the file to parse.
It expects you to return the parsed content and optionaly the file suffix it should use.
If you don't supply a suffix the files will be created without any suffix.
If you can you should supply a suffix, on most Systems files with a suffix like C<.html> or C<.pdf> will be opened with a default application.

    $self->parser(sub {
        my ($file) = @_;

        #... open $file and parse it into $parsed

        return ($parsed, '.html');
    });

=head2 C<Default Parser>

In case there is no Parser specified via C<parser> the parsing will fallback to a Default Parser.
The used default is L<Pod::Simple::HTML>.

=cut

1;

