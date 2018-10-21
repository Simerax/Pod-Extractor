# DISCLAIMER

It looks like there are actually people downloading this. Please be aware that this is only a Prototype right now!
There has been almost zero testing so far!


# NAME

Pod::Generator - A Module to extract Pod Documentation from Perl sourcecode.

# VERSION

Version 0.51

# SYNOPSIS

    use Pod::Generator;
    my $podder = Pod::Generator->new({
        root => 'lib',
        target => 'docs',
    });
    my ($ok, $err) = $podder->run();
    if (!$ok) {
        print "ERROR: $err\n";
    }

# DESCRIPTION

This Module is for extracting Pod Documentation from Perl Sourcecode recursively and converting it into the desired Format.
You give it a entry point on your filesystem and it will extract and parse all POD from every \*.pm and \*.pl file and dump them in your specific target folder

## Functions

### `new($class, $args)`

Function to initalize a `Pod::Generator` instance.
`$args` is a hash reference. You can specify every Attribute right here or use the appropriate setter afterwards.

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

### `run($self)`

Starts the Extraction.
Will create the target Folder if necessary.
Will set `target` to './docs' if there is no specified target.

Does Return 0 on Failure and 1 on Success.
If called in List Context, it will also give you an error message as second return value.

    my ($ok, $err) = $podder->run();
    print "ERROR: $err" if (!$ok);

### `root($self, $folder)`

Method to set/get the root Folder of the pod Extraction.

### `target($self, $folder)`

Method to set/get the target Folder of the pod Extraction.
Appends '/' to the target in case it doesnt have it already

### `overwrite($self, $bool)`

Method to set/get the overwrite Attribute.
This will cause the Extraction to overwrite files in `target` if they exist.
Default is 0 (false).

Every true Value is considered `overwrite == true`

### `parser($self, $parser)`

Method to set/get the Parser for the Pod Extraction.
Expects a Code Reference.

This Function gives you `$file` which is the filepath of the file to parse.
It expects you to return the parsed content and optionaly the file suffix it should use.
If you don't supply a suffix the files will be created without any suffix.
If you can you should supply a suffix, on most Systems files with a suffix like `.html` or `.pdf` will be opened with a default application.

    $self->parser(sub {
        my ($file) = @_;

        #... open $file and parse it into $parsed

        return ($parsed, '.html');
    });

## `Default Parser`

In case there is no Parser specified via `parser` the parsing will fallback to a Default Parser.
The used default is [Pod::Simple::HTML](https://metacpan.org/pod/Pod::Simple::HTML).
