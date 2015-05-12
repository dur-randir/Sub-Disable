package Sub::Disable;
use 5.014;
use strict;

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Sub::Disable', $VERSION);

sub import {
    my $class = shift;
    return unless scalar @_;

    my $args = ref($_[0]) eq 'HASH' ? $_[0] : (scalar grep {ref $_} @_) ? {@_} : {all => \@_};
	my $caller = caller;

    for my $func (@{$args->{method} // []}, @{$args->{all} // []}) {
        disable_method_call($caller, $func);
    }

    for my $func (@{$args->{sub} // []}, @{$args->{all} // []}) {
        disable_named_call($caller, $func);
    }
}

1;

