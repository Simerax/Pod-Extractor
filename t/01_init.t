use strict;
use warnings;

use Test::Simple tests => 11;

use Pod::Generator;



# Initalization via new()
{
    my $generator = Pod::Generator->new();
    ok(ref($generator) eq 'Pod::Generator', 'Pod::Generator::new() works');

    $generator = Pod::Generator->new({
        root => 'source',
        target => 'docs',
        overwrite => 1,
        parser => sub {
            my ($file) = @_;
            return ('pod', '.html');
        }
    });

    ok($generator->{'root'} eq 'source', 'Pod::Generator::new() (with $args) - root is set correctly');
    ok($generator->{'target'} eq 'docs/', 'Pod::Generator::new() (with $args) - target is set correctly');
    ok($generator->{'overwrite'} == 1, 'Pod::Generator::new() (with $args) - overwrite is set correctly');


    if (ref($generator->{'parser'}) eq 'CODE') {
        my ($parsed, $suffix) = $generator->{'parser'}->('file');
        if ($parsed eq 'pod' && $suffix eq '.html') {
            ok('Pod::Generator::new() (with $args) - parser is set correctly');
        } else {
            fail('Pod::Generator::new() (with $args) - failes to set parser');
        }
    } else {
        fail('Pod::Generator::new() (with $args) - failes to set parser (not a code ref!)');
    }
}

# Setters & Getters
{
    my $generator = Pod::Generator->new();
    $generator->root('source');
    ok($generator->root() eq 'source', 'Pod::Generator::root() setter works');
    ok($generator->{'root'} eq 'source', 'Pod::Generator::root() setter works');

    $generator->target('docs');
    ok($generator->target() eq 'docs/', 'Pod::Generator::target() setter works');
    ok($generator->{'target'} eq 'docs/', 'Pod::Generator::target() setter works');
    $generator->target('target/');
    ok($generator->target() eq 'target/', 'Pod::Generator::target() setter works');
    ok($generator->{'target'} eq 'target/', 'Pod::Generator::target() setter works');
}

