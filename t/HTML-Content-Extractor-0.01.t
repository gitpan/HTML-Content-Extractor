# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Content-Extractor-0.01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use_ok 'HTML::Content::ContentExtractor';
use_ok 'HTML::Content::HTMLTokenizer';
use_ok 'HTML::WordTagRatio::WeightedRatio';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $tokenizer = new HTML::Content::HTMLTokenizer('TAG','WORD');

my $ranker = new HTML::WordTagRatio::WeightedRatio();

my $extractor = new HTML::Content::ContentExtractor($tokenizer,$ranker,"test.htm","test.extr");

$extractor->Extract();

open(EXTR,"test.extr");
my @extracted_words = ();
while(<EXTR>)
{
	push(@extracted_words,$_);
}
close(EXTR);

open(COMP,"test.comp");
my @compare_words = ();
while(<COMP>)
{
	push(@compare_words,$_);
}
close(COMP);

ok eq_set(\@extracted_words, \@compare_words), "Extracted [@extracted_words]";
