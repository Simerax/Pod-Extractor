use strict;
use warnings;

use Test::More tests => 4;

use Pod::Generator;


# Root Folder does not exist
{
    my $root_folder = 'root';
    my $generator = Pod::Generator->new();

    if (!-d $root_folder) {
        $generator->root($root_folder);
        my ($ok, $err) = $generator->run();
        ok($ok eq 0, 'Pod::Generator::run() returns correct in list context'); # needs to fail since root does not exist

        if (!$generator->run()) {
            pass('Pod::Generator::run() returns correct in scalar context');
        } else {
            fail('Pod::Generator::run() should have failed since root folder does not exist!');
        }

    }
}

{
    my $root_folder = 'test/source_root';
    my $target_folder = 'test/docs_target';
    if (!-d $root_folder) {
        use File::Path;
        File::Path::make_path($root_folder);
    }
    my $generator = Pod::Generator->new();
    $generator->root($root_folder);
    $generator->target($target_folder);
    my ($ok, $err) = $generator->run();
    ok($ok eq 1 && $err eq '', 'Pod::Generator::run() works');


    if (
        -f $target_folder.'/asd/test.html' &&
        -f $target_folder.'/asd/test.1.html' &&
        -f $target_folder.'/asd/folder/test.2.html'
    ) {
        ok('Pod::Generator::run() - generated Pod files.');
    } else {
        fail('Pod::Generator::run() - Failed while generating Pod files');
    }

    if (-d $target_folder) {
        use File::Path;
        File::Path::remove_tree($target_folder);
    }
}


