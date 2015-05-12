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
__END__

=head1 NAME

Sub::Disable - remove function/method calls from compiled code

=head1 SYNOPSIS

    use Sub::Disable 'debug';

    sub debug { warn "DEBUG INFO: @_" }

    __PACKAGE__->debug(some_heave_debug()); # no-op
    debug(even_more(), heavier_debug()); # no-op

=head1 DESCRIPTION

=head1 CAVEATS

L<Sub::Disable> will remove only those sub/method calls that were compiled after
you use'd L<Sub::Disable>.

If you use L<Sub::Disable> together with L<namespace::clean> and you want to remove
some function as a 'sub', but not as a 'method', you should use L<Sub::Disable> AFTER
L<namespace::clean> or exclude that method from cleaning with '-except'.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
