use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Omegle',
    VERSION_FROM      => 'lib/WWW/Omegle.pm', # finds $VERSION
    PREREQ_PM         => {
        JSON => '',
        'WWW::Mechanize' => '',
        'HTTP::Async' => '',
		'HTTP::Request::Common' => '',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Omegle.pm', # retrieve abstract from module
       AUTHOR         => 'Mischa Spiegelmock <revmischa@cpan.org>') : ()),
);
