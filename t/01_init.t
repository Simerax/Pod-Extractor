use strict;
use warnings;

use Test::Simple tests => 5;

use Pod::Generator;



# Initalization via new()
{
    my $generator = Pod::Generator->new();
    ok(ref($generator) eq 'Pod::Generator', 'Pod::Generator::new() works');
}

# Setters & Getters
{
    my $generator = Pod::Generator->new();
    $generator->root('source');
    ok($generator->root() eq 'source', 'Pod::Generator::root() setter works');
    ok($generator->{'root'} eq 'source', 'Pod::Generator::root() setter works');

    $generator->target('docs');
    ok($generator->target() eq 'docs', 'Pod::Generator::target() setter works');
    ok($generator->{'target'} eq 'docs', 'Pod::Generator::target() setter works');
}

