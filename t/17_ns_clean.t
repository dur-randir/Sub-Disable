use Test::More;
my $test = 1;

package Bar;
use Sub::Disable sub => ['foo'];
use namespace::clean;

sub foo {$test = 2}

package main;

eval{ Bar->foo };
TODO: {
    local $TODO = "unavoidable :(";
    is $test, 2;
}

done_testing;

