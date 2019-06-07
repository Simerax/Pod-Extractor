
=head1 NAME

Pod::Extractor - A Module to extract Pod Documentation from Perl sourcecode.

=head1 VERSION

Version 0.52

=head1 SYNOPSIS

    use Pod::Extractor;
    my $podder = Pod::Extractor->new({
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

=cut

package Pod::Extractor;

our $VERSION = '0.52';

use warnings;
use strict;

use vars qw(@ISA %EXPORT_TAGS);


BEGIN {
	require Exporter;
	@ISA = qw(Exporter);

	%EXPORT_TAGS = (
		PARSER_TAGS => [
			qw(
			  PARSER_FILE
			  PARSER_FILE_CONTENT
			  )
		]
	);

	Exporter::export_ok_tags(
		qw(
		  PARSER_TAGS
		  )
	);
}

use constant {
	PARSER_FILE => 0,
	PARSER_FILE_CONTENT => 1,
};

use File::Basename;
use File::Path;
use File::Find::Rule;
use Pod::Extractor::Helper qw(ret);
use Carp qw (carp croak);


=head3 C<new($class, $args)>

Function to initalize a C<Pod::Extractor> instance.
C<$args> is a hash reference. You can specify every Attribute right here or use the appropriate setter afterwards.

    my $generator = Pod::Extractor->new({
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

=cut


sub new {
	my ($class, $args) = @_;
	my $self = {};
	bless $self, $class;

	$self->root($args->{'root'}) if (defined $args->{'root'});
	$self->parser($args->{'parser'}) if (defined $args->{'parser'});
	$self->target($args->{'target'}) if (defined $args->{'target'});
	$self->overwrite($args->{'overwrite'} || 1);

	return $self;
}

=head3 C<root($self, $folder)>

Method to set/get the root Folder of the pod Extraction.

=cut


sub root {
	my $self = shift;
	$self->{'root'} = shift if (@_);
	$self->{'root'};
}

=head3 C<target($self, $folder)>

Method to set/get the target Folder of the pod Extraction.
Appends '/' to the target in case it doesnt have it already

=cut


sub target {
	my $self = shift;
	my $target = shift;
	if ($target) {
		$self->{'target'} = $target =~ /\/$/ ? $target : $target . '/';
	}
	$self->{'target'};
}

=head3 C<overwrite($self, $bool)>

Method to set/get the overwrite Attribute.
This will cause the Extraction to overwrite files in C<target> if they exist.
Default is 1 (true).

Every true Value is considered C<overwrite == true>

=cut


sub overwrite {
	my $self = shift;
	if (@_) {
		$self->{'overwrite'} = shift;
	}
	$self->{'overwrite'};
}

=head3 C<parser($self, $parser)>

Method to set/get the Parser for the Pod Extraction.
Expects a Code Reference.

This Function gives you C<$file> which is the filepath of the file to parse.
It expects you to return the parsed content and optionaly the file suffix it should use.
If you don't supply a suffix the files will be created without any suffix.
If you can you should supply a suffix, on most Systems files with a suffix like C<.html> or C<.pdf> will be opened with a default application.

    $self->parser(sub {
        my ($file, $content) = @_;

        #... open $file and parse it into $parsed

        return ($parsed, '.html');
    });

=cut


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

=head3 C<run($self)>

Starts the Extraction.
Will create the target Folder if necessary.
Will set C<target> to './docs' if there is no specified target.

Does Return 0 on Failure and 1 on Success.
If called in List Context, it will also give you an error message as second return value.

    my ($ok, $err) = $podder->run();
    print "ERROR: $err" if (!$ok);

=cut


sub run {
	my ($self) = @_;

	my ($ok, $err, $files) = $self->_find_files();
	if (!$ok) {
		return ret(0, $err);
	}

	$self->target('./docs') unless (defined $self->target());

	foreach my $file (@$files) {
		my ($ok, $err, $fileContent) = Pod::Extractor::Helper::read_file($file);
		if (!$ok) {
			carp $err;
			next;
		}

		my ($content, $filetype) = $self->parser()->($file, $fileContent);
		next unless $content;
		
		$filetype = '' unless (defined $filetype);

		my ($name, $path, $suffix) = fileparse($file);
		$name = Pod::Extractor::Helper::get_basename($name) unless $suffix; # fileparse doesnt really get the right basname (suffix is still present)

		my $root = $self->root();
		$path =~ s/^\Q$root\E//;

		my $target_dir = $self->target().$path;
		my $target_file = $target_dir.'/'.$name.$filetype;

		next if (-f $target_file && !$self->overwrite());

		if (!-d $target_dir) {
			my ($ok, $err) = Pod::Extractor::Helper::create_dir($target_dir);
			if (!$ok) {
				carp $err;
				next;
			}
		}

		($ok, $err) = Pod::Extractor::Helper::write_file($target_file, $content);
		if (!$ok) {
			carp $err;
			next;
		}

	}
	ret(1, '');
}


# _find_files
#	returns a list of all files found in $self->root()
#
# Returnvalue:
#	[Scalar]			$ok		=> 0 on Failure, 1 on success
#	[Scalar]			$err	=> Error String in case !$ok
#	[Array Reference]	$files	=> List of all files that were found
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
	return ret(0, $err, undef) if (!$ok);

	my $finder = File::Find::Rule->new();
	$finder->file()->name('*.pm', '*.pl')->canonpath();

	my @files;
	if ($type eq '') {
		@files = $finder->in($self->root());
	}elsif ($type eq 'ARRAY') {
		@files = $finder->in(@{$self->root()});
	} else { # since we do _check_root() we should never get here but oh well you never know
		croak "Type '$type' not supported as root folder!";
	}
	return ret(1, '', \@files);
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

	return ret(0, 'Root not specified') unless defined $self->root();

	my $type = ref($self->root());

	if ($type eq '') {
		$check->($self->root());
		return ret(1, '', $type);
	}elsif ($type eq 'ARRAY') {
		$check->($_) foreach(@{$self->root()});
		return ret(1, '', $type);
	} else {
		my $err = "Type $type is not supported as 'root' directory!";
		carp $err;
		return ret(0, $err, undef);
	}
}


=head2 C<More on Parsers>

=head3 C<Default Parser>

In case there is no Parser specified via C<parser> the parsing will fallback to a Default Parser.
The used default is L<Pod::Simple::HTML>.

=head3 C<Parser Tags>

Since L<Pod::Extractor> gives you multiple values for your parsing you can choose which to use via Parser Tags.
Maybe you only want the Filecontent and not its Path.

	use Pod::Extractor qw(:PARSER_TAGS); # also import Parser tags into namespace

	my $generator = Pod::Extractor->new({
		root => 'lib',
		target => 'docs',
		parser => sub {
			my $fileContent = @_[PARSER_FILE_CONTENT]; # just get file content as parameter
		}
	});

The Following Parser Tags are available right now.

=over 2

=item PARSER_FILE

The Filepath of the file that has to be parsed

=item PARSER_FILE_CONTENT

The Content of the file that has to be parsed

=back

=cut

1;

