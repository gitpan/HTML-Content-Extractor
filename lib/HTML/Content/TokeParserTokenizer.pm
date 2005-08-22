package HTML::Content::TokeParserTokenizer;

use strict;
use warnings;
use Carp;
use HTML::TokeParser;
use HTML::Content::HTMLTokenizer;

use vars qw(@ISA);
@ISA = qw(HTML::Content::HTMLTokenizer);

# new - constructs TokeParserTokenizer object
# - preconditions: 1st arg points to string to indicate tag
#		   2nd arg points to string to indicate word
# - postconditions: 	TokeParserTokenizer is constructed
sub new
{
	my $invocant = shift;	
    	my $class   = ref($invocant) || $invocant;
    	my($self) = new HTML::Content::HTMLTokenizer(@_);
	
        return(bless($self, $class));
}
sub Tokenize
{
	my $self = shift;
	my $doc = shift;
	my @seq = ();
	my @N = ();
	my @T = ();
	my %tokens = ();
	
	my $parse = HTML::TokeParser->new(\$doc) || die "HTML::TokeParser can't open: $!";
	my $i = 0;
	my $tagcnt = 0;
	my $wordcnt = 0;
	while (my $token = $parse->get_token) 
	{
	     	if ($$token[0] ne 'T')
	     	{
	     		$i++;
	     		$tagcnt++;
	     		push(@seq,$self->{TAGMARKER});
	     		push(@N,$wordcnt);
			push(@T,$tagcnt);	
	     	}
	     	else
	     	{
			my $text = $$token[1];

			#Remove carriage returns and newlines
			$text =~ s/[\n\r]+/ /g;

			#Remove HTML spaces
			$text =~ s/\Q&nbsp;\E/ /g;

			$text =~ s/\Q&quot;\E/\"/g;
			$text =~ s/\Q&mdash;\E/-/g;

			#Remove HTML directives
			$text =~ s/\Q&\E.*?\Q;\E/ /g;

			my @line = split(/\s+/,$text);
			foreach my $word (@line)
			{
				$wordcnt++;
				$i++;
				$tokens{$i} = $word;
				push(@seq,$self->{WORDMARKER});
				push(@N,$wordcnt);
				push(@T,$tagcnt);
			}
	     	}
	}
	
	return (\@N,\@T,\@seq,\%tokens);
}
1;
