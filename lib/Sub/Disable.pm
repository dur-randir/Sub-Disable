package Sub::Disable;
use 5.014;
use strict;

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Sub::Disable', $VERSION);

sub import {
    my $class = shift;
    return unless scalar @_;

    my $args = ref($_[0]) eq 'HASH' ? $_[0] : (scalar grep {ref $_} @_) ? {@_} : {any => \@_};
	my $caller = caller;

    for my $func (@{$args->{method} // []}, @{$args->{any} // []}) {
        disable_method_call($caller, $func);
    }

    for my $func (@{$args->{sub} // []}, @{$args->{any} // []}) {
        disable_named_call($caller, $func);
    }
}

1;
__END__

=head1 NAME

Sub::Disable - remove function/method call from the compiled code

=head1 SYNOPSIS

    use Sub::Disable 'debug', 'foo', 'bar'; # without specification - both method + sub form calls

    use Sub::Disable method => ['debug'];
    use Sub::Disable sub    => ['debug'];
    use Sub::Disable {
        method => ['foo'],
        sub    => ['bar'],
    };

    sub debug { warn "DEBUG INFO: @_" }

    __PACKAGE__->debug(some_heave_debug()); # no-op
    debug(even_more(), heavier_debug()); # no-op

=head1 DESCRIPTION

This module allows you to turn compile-time resolvable function or method call into no-op (together with
all arguments computation). This is useful for debugging and/or logging, when you don't want to make 
your production code slower.

Note that 'compile-time resolvable method call' is a method call on a literal package name

    __PACKAGE__->method
    # or
    Some::Package->method

and does not consider inheritance.

L<Sub::Disable> distinguishes between sub and method calls and, by default,
removes both of them. If you want to remove only one type - use appropriate form of import.

=head1 CAVEATS

L<Sub::Disable> will remove only those sub/method calls that were compiled after
you have use'd it.

If you use L<Sub::Disable> together with L<namespace::clean> and you want to remove
some function as a sub call, but not as a method call, you should use L<Sub::Disable> 
B<after> using L<namespace::clean> or exclude that method with '-except'.

=head1 SEE ALSO

L<B::Hooks::OP::Check> and various OP_check[] related core stuff.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
