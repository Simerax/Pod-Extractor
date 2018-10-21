use strict;
use warnings;

use Test::More tests => 5;
use autodie;
use Pod::Generator;

# UTILITIES TO CREATE TESTS more easily
my $dummy_pod = <<'END'

=head1 NAME

this is a dummy name

=head1 SYNOPSIS

NOPE

=cut

END
;


my $create_file = sub {
    my ($file) = @_;
    my $fh;
    open($fh, '>', $file);
    print $fh "$dummy_pod";
    close($fh);
    return 1;
};

my $create_files = sub {
    my ($root_folder, $files, $suffix) = @_;

    $suffix = '.pm' unless defined $suffix;

    if (!-d $root_folder) {
        use File::Path;
        File::Path::make_path($root_folder);
    }

    foreach(@$files) {
        $create_file->($root_folder.'/'.$_.$suffix);
    }
};

my $files_in_target = sub {
    my ($target, $suffix, $files) = @_;

    foreach(@$files) {
        my $filePath = $target.'/'.$_.$suffix;
        if (!-f $filePath) {
            # use Carp qw(carp); 
            # carp "File $filePath was not created!\n";
            return 0;
        }
    }
    return 1;
};

my $remove_folder = sub {
    my ($folder) = @_;
    if (-d $folder) {
        use File::Path;
        File::Path::remove_tree($folder);
    }
};


# TESTS
{

    my @files = qw(
        one
        two
    );

    my $root_folder = 'test/source_root';
    my $target_folder = 'test/docs_target';
    $create_files->($root_folder, \@files, '.pm');

    my $generator = Pod::Generator->new();
    $generator->root($root_folder);
    $generator->target($target_folder);
    my ($ok, $err) = $generator->run();
    ok($ok eq 1 && $err eq '', 'Pod::Generator::run() works');

    ok($files_in_target->($target_folder, '.html', \@files) eq 1, 'Pod::Generator::run() - generated files.');

    $remove_folder->($root_folder);
    $remove_folder->($target_folder);
}

{
    my $root_0 = 'test/source';
    my $root_1 = 'test/anotherone/';
    my $files_root0 = [qw( a b c )];
    my $files_root1 = [qw( d e f )];
    my $root = [$root_0, $root_1];
    my $target = qw( test/docs );

    $create_files->($root->[0], $files_root0, '.pm');
    $create_files->($root->[1], $files_root1, '.pm');


    my $generator = Pod::Generator->new({
        root => $root,
        target => $target,
    });
    my ($ok, $err) = $generator->run();

    if (
        $files_in_target->($target.'/'.$root_0, '.html', $files_root0) &&
        $files_in_target->($target.'/'.$root_1, '.html', $files_root1)
    ) {
        pass('Pod::Generator::run() works with multiple root folders');
    } else {
        fail('Pod::Generator::run() fails when multiple root folders are used');
    }

    $remove_folder->($_) foreach(@$root);
    $remove_folder->($target);
}

# does not parse files with different suffix
{
    my $root = 'test/source';
    my $correct_files = [qw(a b c)];
    my $invalid_files = [qw(invalid invalid2)];
    my $target = 'test/docs';

    $create_files->($root, $correct_files, '.pm');
    $create_files->($root, $invalid_files, '.h'); # should not be parsed since suffix is different

    my $generator = Pod::Generator->new({
        root => $root,
        target => $target,
    });
    my ($ok, $err) = $generator->run();

    if (
        $files_in_target->($target, '.html', $correct_files) &&
        !$files_in_target->($target, '.html', $invalid_files)
    ) {
        pass('Pod::Generator::run() - only parses correct files');
    } else {
        fail('Pod::Generator::run() - parses wrong filetype!');
    }

    $remove_folder->($root);
    $remove_folder->($target);

}

{
    my $root = 'test/source';
    my $target = 'test/docs';
    my $files = [qw(A B C)];
    $create_files->($root, $files);

    no Pod::Generator;

    use Pod::Generator qw(:PARSER_TAGS);
    
    my $generator = Pod::Generator->new({
        root => $root,
        target => $target,
        parser => sub {
            my $file = $_[PARSER_FILE];
            my $content = $_[PARSER_FILE_CONTENT];

            if (!-f $file || (!defined $content) || ref($content) ne 'ARRAY') {
                fail("Pod::Generator::run() - parser tags are wrong!");
            }
            return($content, '.html');
        }
    });

    my ($ok, $err) = $generator->run();

    pass("Pod::Generator::run() - parser tags work");
}




$remove_folder->('test');






