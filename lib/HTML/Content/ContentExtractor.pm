=head1 NAME

HTML::Content::ContentExtractor - Perl module for extracting content from HTML documents. 

=head1 SYNOPSIS

  use HTML::WordTagRatio::WeightedRatio;
  use HTML::Content::HTMLTokenizer;
  use HTML::Content::ContentExtractor;
  
  my $tokenizer = new HTML::Content::HTMLTokenizer('TAG','WORD');
  
  my $ranker = new HTML::WordTagRatio::WeightedRatio();
  
  my $extractor = new HTML::Content::ContentExtractor($tokenizer,$ranker,"index.html","index.extr");
  
  $extractor->Extract();
  
=head1 DESCRIPTION

HTML::Content::ContentExtractor attempts to extract the content from HTML documents. It attempts to remove tags, scripts and boilerplate text from the documents by trying to find the region of the HTML document that has the maximum ratio of words to tags. 

=head2 Methods

=over 4

=item * my $extractor = new HTML::Content::ContentExtractor($tokenizer, $ratio, $inputfilename, $extractfilename)

Initializes HTML::Content::ContentExtractor with 1) an object that can tokenize HTML 2) an object that can compute the ratio of Words to Tags 3) an input filename and 4) an output filename.

=item * $extractor->Extract()

Attempts to extract content from the $inputfilename.

=back

=head1 AUTHOR

Jean Tavernier (jj.tavernier@gmail.com)

=head1 COPYRIGHT

Copyright 2005 Jean Tavernier.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

ContentExtractorDriver.pl (1).

=cut

package HTML::Content::ContentExtractor;

use strict;
use warnings;
use Carp;
use HTML::WordTagRatio::Ratio;
use HTML::Content::HTMLTokenizer;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
$VERSION = '0.01';
use fields qw(Tokenizer Ratio Document Output);


# new - constructs ContentExtractor object
# - preconditions: 1st arg is a reference to a HTMLTokenizer object
#		   2nd arg is a reference to a Ratio object
#		   3rd arg is an HTML file name
#		   4th arg is an output file
# - postconditions: ContentExtractor is constructed
sub new
{
	my $invocant = shift;	
    	my $class   = ref($invocant) || $invocant;
    	
    	my $self = fields::new($invocant);
    	$self->{Tokenizer} = shift;
    	croak "ContentExtractor: first argument must be an HTMLTokenizer" unless $self->{Tokenizer}->isa('HTML::Content::HTMLTokenizer');
    	$self->{Ratio} = shift;
    	croak "ContentExtractor: second argument must be an HTMLTokenizer" unless $self->{Ratio}->isa('HTML::WordTagRatio::Ratio');
    	$self->{Document} = shift;
   	$self->{Output} = shift;
    	
    	return bless($self, $class);
}

sub Extract
{
	my $self = shift;
	
	# Read document
	open(HTML,$self->{Document}) or croak "ContentExtractor::ExtractContent: Cannot open $self->{Document} ($!)\n";
	my $html = join("",<HTML>);
	close(HTML);
	
	my ($N,$T,$seq,$tokens) = $self->{Tokenizer}->Tokenize($html);
	
	my ($i,$j,$max) = $self->FindBestRange($N,$T,$seq);
	
	$self->PrintContent($tokens,$i,$j);
}
sub FindBestRange
{
	my $self = shift;
	my $tN = shift;
	my $tT = shift;
	my $tS = shift;
	my @N = @{$tN};
	my @T = @{$tT};
	my @S = @{$tS};
	my $best_i = 0;
	my $best_j = $#N;
	my $max = 0;

	my $WordMarker = $self->{Tokenizer}->GetWordMarker();
	
	for (my $i = 0;$i <= $#N;$i++)
	{
		for (my $j = $i + 1; $j <= $#N; $j++)
		{
			if ($S[$i] eq $WordMarker && $S[$j] eq $WordMarker)
			{
				# Only compute the score if we have Si = N and Sj = N
				# and Si-1 = T and Sj+1 = T
				if (
					($i == 0 || $S[$i] ne $S[$i - 1]) 
					&& 
					($j == $#N || $S[$j] ne $S[$j + 1])
				)
				{
					my $tmp = $self->{Ratio}->RangeValue($i,$j,\@N,\@T);
					if ($tmp > $max)
					{
						$best_i = $i;
						$best_j = $j;
						$max = $tmp;
					}
				}				
			}
		}
	}
	return ($best_i,$best_j,$max);
}
sub PrintContent
{
	my $self = shift;
	my $tokens = shift;
	my $i = shift;
	my $j = shift;
	
	open(OUTPUT,">$self->{Output}") or croak "ContentExtractor::ExtractContent: Cannot open $self->{Output} ($!)\n";
	foreach my $key (sort {$a <=> $b} (keys %$tokens))
	{
		$$tokens{$key} =~ s/\s+//g;
		if (length($$tokens{$key}) == 0)
		{
			next;
		}

		if ($key >= $i && $key <= $j)
		{
			print OUTPUT "$$tokens{$key} ";
		}
	}
	close(OUTPUT);
}
1;