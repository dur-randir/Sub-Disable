use 5.014;
use ExtUtils::MakeMaker;

system 'pod2text lib/Sub/Disable.pm > README';

WriteMakefile(
    NAME            => 'Sub::Disable',
    VERSION_FROM    => 'lib/Sub/Disable.pm',
    AUTHOR          => ['Sergey Aleynikov <randir@cpan.org>'],
    PREREQ_PM       => {
    },
    TEST_REQUIRES   => {
        'Test::More'        => 0,
        'Test::Exception'   => 0,
    },
    META_MERGE      => {
        resources     => {
            repository  => 'https://github.com/dur-randir/Sub-Disable',
        },
    },
    ABSTRACT_FROM   => 'lib/Sub/Disable.pm',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.014,
);

{
    package MY;
    sub postamble { '$(OBJECT) : xs/compat.h' }
}

