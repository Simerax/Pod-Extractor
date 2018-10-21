use strict;
use warnings;

use Test::Simple tests => 11;

use Pod::Extractor;



# Initalization via new()
{
    my $generator = Pod::Extractor->new();
    ok(ref($generator) eq 'Pod::Extractor', 'Pod::Extractor::new() works');

    $generator = Pod::Extractor->new({
        root => 'source',
        target => 'docs',
        overwrite => 1,
        parser => sub {
            my ($file) = @_;
            return ('pod', '.html');
        }
    });

    ok($generator->{'root'} eq 'source', 'Pod::Extractor::new() (with $args) - root is set correctly');
    ok($generator->{'target'} eq 'docs/', 'Pod::Extractor::new() (with $args) - target is set correctly');
    ok($generator->{'overwrite'} == 1, 'Pod::Extractor::new() (with $args) - overwrite is set correctly');


    if (ref($generator->{'parser'}) eq 'CODE') {
        my ($parsed, $suffix) = $generator->{'parser'}->('file');
        if ($parsed eq 'pod' && $suffix eq '.html') {
            ok('Pod::Extractor::new() (with $args) - parser is set correctly');
        } else {
            fail('Pod::Extractor::new() (with $args) - failes to set parser');
        }
    } else {
        fail('Pod::Extractor::new() (with $args) - failes to set parser (not a code ref!)');
    }
}

# Setters & Getters
{
    my $generator = Pod::Extractor->new();
    $generator->root('source');
    ok($generator->root() eq 'source', 'Pod::Extractor::root() setter works');
    ok($generator->{'root'} eq 'source', 'Pod::Extractor::root() setter works');

    $generator->target('docs');
    ok($generator->target() eq 'docs/', 'Pod::Extractor::target() setter works');
    ok($generator->{'target'} eq 'docs/', 'Pod::Extractor::target() setter works');
    $generator->target('target/');
    ok($generator->target() eq 'target/', 'Pod::Extractor::target() setter works');
    ok($generator->{'target'} eq 'target/', 'Pod::Extractor::target() setter works');
}

