=head1 NAME

HTML::Content::HTMLTokenizer - Perl module to tokenize HTML documents. 

=head1 SYNOPSIS

  use HTML::Content::HTMLTokenizer;
  
  my $tokenizer = new HTML::Content::HTMLTokenizer('TAG','WORD');
  
  open(HTML,"index.html");
  my $doc = join("",<HTML>);
  close(HTML);
  
  my ($word_count_arr_ref,$tag_count_arr_ref,$token_type_arr_ref,$token_hash_ref) = $tokenizer->Tokenize($doc);
   				
=head1 DESCRIPTION

HTML::Content::HTMLTokenizer has one main method, Tokenize, which tokenizes a HTML document into a sequence of 'TAG' and 'WORD' tokens. 

=head2 Methods

=over 4

=item * my $tokenizer = new HTML::Content::HTMLTokenizer($tagMarker,$wordMarker)

Initializes HTML::Content::HTMLTokenizer. 
	
$tagMarker - String that will represent tags in the token sequence returned from Tokenize.

$wordMarker - String that will represent words in the token sequence returned from Tokenize.

=item * my (\@WordCount,\@TokenCount,\@Sequence,\%Tokens) = $tokenizer->Tokenize(\$htmldocument);

$WordCount[$i] is the number of word tokens before or at the ith token in the input HTML document. 

$TagCount[$i] is the number of tag tokens before or at the ith token in the input HTML document.

$Sequence[$i] is the type of token at the ith spot in the input HTML document. Either $tagMarker or $wordMarker.

$Tokens{$i} is the word at the ith spot in the input HTML document. This is defined only if there is a word at the ith spot in the document.

=back

=head1 AUTHOR

Jean Tavernier (jj.tavernier@gmail.com)

=head1 COPYRIGHT

Copyright 2005 Jean Tavernier.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

ContentExtractorDriver.pl (1), HTML::Content::ContentExtractor (3), HTML::WordTagRatio::Ratio (3),HTML::WordTagRatio::WeightedRatio (3), HTML::WordTagRatio::SmoothedRatio (3), HTML::WordTagRatio::RelativeRatio (3), HTML::WordTagRatio::ExponentialRatio (3), HTML::WordTagRatio::NormalizedRatio (3).

=cut


package HTML::Content::HTMLTokenizer;

use strict;
use warnings;
use Carp;

use fields qw(TAGMARKER WORDMARKER);

# new - constructs HTMLTokenizer object
# - preconditions: 1st arg points to string to indicate tag
#		   2nd arg points to string to indicate word
# - postconditions: HTMLTokenizer is constructed
sub new
{
	my $invocant = shift;	
    	my $class   = ref($invocant) || $invocant;
    	my $tagMarker = shift or croak "HTMLTokenizer: TagMarker missing \n\tex: HTMLTokenizer tok = new HTMLTokenizer('TAG','WORD');\n";
    	my $wordMarker = shift or croak "HTMLTokenizer: WordMarker missing \n\tex: HTMLTokenizer tok = new HTMLTokenizer('TAG','WORD');\n";
    	
    	my $self = fields::new($invocant);
    	$self->{TAGMARKER} = $tagMarker;
    	$self->{WORDMARKER} = $wordMarker;
    	
    	return bless($self, $class);
}
sub GetTagMarker
{
	my $self = shift;
	return $self->{TAGMARKER};
}
sub GetWordMarker
{
	my $self = shift;
	return $self->{WORDMARKER};
}
sub Tokenize
{
	my $self = shift;
	my $doc = shift;
	my @N = ();
	my @T = ();
	my %tokens = ();
	
	#Remove carriage returns and newlines
	$doc =~ s/[\n\r]+/ /g;
	
	#Eliminate comments
	$doc =~ s/(<!--.*?-->)/ <> /gis;
	
	#Eliminate scripts
	$doc =~ s/(<script.*?>.+?<\/script>)/ <> /gis;
	
	#Eliminate scripts
	$doc =~ s/(<style.*?>.+?<\/style>)/ <> /gis;
	
	#Eliminate tag words
	$doc =~ s/(<.+?>)/ <> /gs;
	
	#Remove HTML spaces
	$doc =~ s/\Q&nbsp;\E/ /g;

	$doc =~ s/\Q&quot;\E/\"/g;
	$doc =~ s/\Q&mdash;\E/-/g;

	#Remove HTML directives
	$doc =~ s/\Q&\E.*?\Q;\E/ /g;
		
	my @seq = split(/\s+/,$doc);
	
	my $tagcnt = 0;
	my $wordcnt = 0;
	for(my $i = 0; $i <= $#seq; $i++)
	{
		if ($seq[$i] eq '<>')
		{
			$seq[$i] = $self->{TAGMARKER};
			$tagcnt++;
		}
		else
		{
			$tokens{$i} = $seq[$i];
			$seq[$i] = $self->{WORDMARKER};
			$wordcnt++;
		}
		push(@N,$wordcnt);
		push(@T,$tagcnt);
	}
	return (\@N,\@T,\@seq,\%tokens);
}
1;