use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'OnLDAP',
	       VERSION_FROM => 'OnLDAP.pm',
	       PREREQ_PM => {},
	       ABSTRACT_FROM => 'OnLDAP.pm',
	       AUTHOR => 'Salvador Fandiño <sfandino\@yahoo.com>');
