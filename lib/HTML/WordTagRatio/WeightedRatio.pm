=head1 NAME

HTML::WordTagRatio::WeightedRatio - Perl module for determining the ratio of words to tags in a range of tokens in an HTML document. 

=head1 SYNOPSIS

  use HTML::WordTagRatio::WeightedRatio;
  use HTML::Content::HTMLTokenizer;
  use HTML::Content::ContentExtractor;
  
  my $tokenizer = new HTML::Content::HTMLTokenizer('TAG','WORD');
  
  open(HTML,"index.html");
  my $doc = join("",<HTML>);
  close(HTML);
  
  my ($word_count_arr_ref,$tag_count_arr_ref,$token_type_arr_ref,$token_hash_ref) = $tokenizer->Tokenize($doc);
  
  my $ratio = new HTML::WordTagRatio::WeightedRatio();
    
  my $value = $ratio->RangeValue(0, @$word_count_arr_ref, 
  				$word_count_arr_ref, $tag_count_arr_ref);
  				
=head1 DESCRIPTION

HTML::WordTagRatio::WeightedRatio computes a ratio of Words to Tags for a given range. In psuedo code, the ratio is 

Words^2/(Words + Tags)

=head2 Methods

=over 4

=item * my $ratio = new HTML::WordTagRatio::WeightedRatio()

Initializes HTML::WordTagRatio::WeightedRatio

=item * my $value = $ratio->RangeValue($start, $end, \@WordCount, \@TagCount)

$value is computed as follows:
	
	($WordCount[$end] - $WordCount[$start])**2/(($WordCount[$end] - $WordCount[$start]) + ($TagCount[$end] - $TagCount[$start]))
	
This is the number of words in the range squared, divided by the total number of tags in range. $WordCount[$i] is the number of word tokens before or at the ith token in the input HTML document. $TagCount[$i] is the number of tag tokens before or at the ith token in the input HTML document.

=back

=head1 AUTHOR

Jean Tavernier (jj.tavernier@gmail.com)

=head1 COPYRIGHT

Copyright 2005 Jean Tavernier.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

ContentExtractorDriver.pl (1), HTML::Content::HTMLTokenizer (3), HTML::Content::ContentExtractor (3), HTML::WordTagRatio::Ratio (3), HTML::WordTagRatio::SmoothedRatio (3), HTML::WordTagRatio::RelativeRatio (3), HTML::WordTagRatio::ExponentialRatio (3), HTML::WordTagRatio::NormalizedRatio (3).

=cut

package HTML::WordTagRatio::WeightedRatio;
use strict;
use warnings;
use Carp;
use HTML::WordTagRatio::Ratio;
use vars qw(@ISA);
@ISA = qw(HTML::WordTagRatio::Ratio);

# new - constructs WeightedRatio object
# - preconditions: 	none
# - postconditions: 	WeightedRatio is constructed
sub new
{
	my $invocant = shift;	
    	my $class   = ref($invocant) || $invocant;
    	my($self) = new HTML::WordTagRatio::Ratio();
	
        return(bless($self, $class));
}
# RangeValue - returns value of a range of tokens
# - preconditions: 	1st arg is an integer >= 0 and < length of @{3rd argument}
#			2nd arg is an integer > 1st arg and < length of @{3rd argument}
#			3rd arg is an array ref which points to an array of monotonically
#				increasing integers, indicating the number of words found
#				in the HTML document before or at the i_th token (i being an
#				index into the array)
#			4th arg is an array ref which points to an array of monotonically
#				increasing integers, indicating the number of tags found
#				in the HTML document before or at the i_th token (i being an
#				index into the array)
# - postconditions: 	floating point value returned indicating the value of the range
sub RangeValue
{
	my $self = shift;
	my $i = shift;
	my $j = shift;
	my $tN = shift;
	my $tT = shift;
	my @N = @{$tN};
	my @T = @{$tT};
	
	if ($j <= $i)
	{
		return -1;
	}
	my $NinRange = $N[$j] - $N[$i];
	my $TinRange = $T[$j] - $T[$i];
	return $NinRange**2/($NinRange + $TinRange);
}
1;