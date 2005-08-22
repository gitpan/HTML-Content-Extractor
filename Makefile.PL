use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @pgms_to_install = qw( ContentExtractorDriver.pl );

WriteMakefile(
	# The module name
	
	    'NAME'		=> 'HTML::Content::ContentExtractor',
	
	# Version Number
	
	    VERSION_FROM      => 'lib/HTML/Content/ContentExtractor.pm', # finds $VERSION
	
	# List any required Perl modules
	
	    'PREREQ_PM'		=> {
	    	HTML::TokeParser => 0, 
	    	HTML::TagSet => 0 
	    }, # Module::Name => 1.1
	
	# Run this subroutine prior to creating makefile
	
	    'CONFIGURE'         => \&configSub,
	
	# choose the perl set of installation directories. 
	# choices are site (default), vendor, and perl. 
	
	    'INSTALLDIRS'	=> 'site',
	
	## man files are categorized as follows:
	##  Man1 - Applications and Utilities
	##  Man2 - System Calls
	##  Man3 - C Libraries
	##  Man4 - Device Drivers
	##  Man5 - File Formats
	##  Man6 - games
	##  Man8 - system administration
	##  .pl and .sh files should go into man1, and .pm to man3
	##
	
	
	
	'MAN3PODS' =>  {
			'lib/HTML/Content/HTMLTokenizer.pm' => '$(INST_MAN3DIR)/HTML/Content/HTMLTokenizer.3',
			'lib/HTML/Content/TokeParserTokenizer.pm' => '$(INST_MAN3DIR)/HTML/Content/TokeParserTokenizer.3',
			'lib/HTML/Content/ContentExtractor.pm' => '$(INST_MAN3DIR)/HTML/Content/ContentExtractor.3',
			'lib/HTML/WordTagRatio/Ratio.pm' => '$(INST_MAN3DIR)/HTML/WordTagRatio/Ratio.3',
			'lib/HTML/WordTagRatio/WeightedRatio.pm' => '$(INST_MAN3DIR)/HTML/WordTagRatio/WeightedRatio.3',
			'lib/HTML/WordTagRatio/NormalizedRatio.pm' => '$(INST_MAN3DIR)/HTML/WordTagRatio/NormalizedRatio.3',
			'lib/HTML/WordTagRatio/SmoothedRatio.pm' => '$(INST_MAN3DIR)/HTML/WordTagRatio/SmoothedRatio.3',
			'lib/HTML/WordTagRatio/ExponentialRatio.pm' => '$(INST_MAN3DIR)/HTML/WordTagRatio/ExponentialRatio.3',
			'lib/HTML/WordTagRatio/RelativeRatio.pm' => '$(INST_MAN3DIR)/HTML/WordTagRatio/RelativeRatio.3'
		 },
	
	## executable files to be installed, copied to INST_SCRIPT
	## and then installed to /bin,  man pages to /man1 (in the
	## typical case.  
	
	    'EXE_FILES'         => [
				      map ("$_", @pgms_to_install)
				 ],
	
	## PM enumerates where .pm and .pl files should be installed. Use
	## this is you want to rearrange the installed versions of things.
	## PM requires a hashref as input. These are installed to /lib,
	## and the man pages to /man3 (in the typical case). 
	
		'PM' =>         {
		'lib/HTML/Content/HTMLTokenizer.pm' => '$(INST_LIB)/HTML/Content/HTMLTokenizer.pm',
		'lib/HTML/Content/TokeParserTokenizer.pm' => '$(INST_LIB)/HTML/Content/TokeParserTokenizer.pm',
		'lib/HTML/Content/ContentExtractor.pm' => '$(INST_LIB)/HTML/Content/ContentExtractor.pm',
		'lib/HTML/WordTagRatio/Ratio.pm' => '$(INST_LIB)/HTML/WordTagRatio/Ratio.pm',
		'lib/HTML/WordTagRatio/WeightedRatio.pm' => '$(INST_LIB)/HTML/WordTagRatio/WeightedRatio.pm',
		'lib/HTML/WordTagRatio/NormalizedRatio.pm' => '$(INST_LIB)/HTML/WordTagRatio/NormalizedRatio.pm',
		'lib/HTML/WordTagRatio/SmoothedRatio.pm' => '$(INST_LIB)/HTML/WordTagRatio/SmoothedRatio.pm',
		'lib/HTML/WordTagRatio/ExponentialRatio.pm' => '$(INST_LIB)/HTML/WordTagRatio/ExponentialRatio.pm',
		'lib/HTML/WordTagRatio/RelativeRatio.pm' => '$(INST_LIB)/HTML/WordTagRatio/RelativeRatio.pm'
		} ,
	
	## what happens when you run "make test"
	
	    'test' 		=> {'TESTS' => 't/HTML-Content-Extractor-0.01.t'}, 
	
	    'clean'               => { 'FILES' => 'HTML-Content-Extractor-*' },

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Content/ContentExtractor.pm', # retrieve abstract from module
       AUTHOR         => 'Jean Tavernier <j.j.tavernier@gmail.com>') : ()),
);

sub configSub {

print "#################################################################\n";
print " You are running Makefile.PL. When this finishes, remember that you\n";
print " will also need to run the following to finish the install of HTML-Content-Extractor:\n";
print "\n";
print "        make\n";
print "        make test\n";
print "        make install\n";
print "\n";
print " if \"make install\" fails and indicates that you don\'t have proper\n";
print " permissions to install, you do have the option to install HTML-Content-Extractor in\n";
print " a local directory of your own choosing. You can do this as follows:\n";
print "\n";
print "        perl Makefile.PL PREFIX=/MYDIR\n";
print "        make\n";
print "        make test\n";
print "        make install\n";
print "\n";
print " where /MYDIR is a directory that you own and can write to.\n";
print "\n";
print " After all this is done, you can run \"make clean\" to remove some\n";
print " of the files created during installation\n";
print "#################################################################\n";

return {};  
}