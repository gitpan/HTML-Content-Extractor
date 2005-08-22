#!/usr/bin/perl

=head1 NAME

ContentExtractorDriver.pl - Driver for HTML Content Extractor

=head1 SYNOPSIS

  perl ContentExtractorDriver.pl <input file> <output file> <Ratio type>
  
=head1 DESCRIPTION

ContentExtractorDriver.pl attempts to extract the content from HTML documents. It attempts to remove tags, scripts and boilerplate text from the documents by trying to find the region of the HTML document that has the maximum ratio of words to tags. 

=head1 AUTHOR

Jean Tavernier (jj.tavernier@gmail.com)

=head1 COPYRIGHT

Copyright 2005 Jean Tavernier.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::Content::ContentExtractor(3).

=cut

use strict;
use warnings;
use Carp;
use HTML::WordTagRatio::Ratio;
use HTML::WordTagRatio::NormalizedRatio;
use HTML::WordTagRatio::RelativeRatio;
use HTML::WordTagRatio::SmoothedRatio;
use HTML::WordTagRatio::ExponentialRatio;
use HTML::WordTagRatio::WeightedRatio;
use HTML::Content::HTMLTokenizer;
use HTML::Content::HTMLTokenizerTokeParser;
use HTML::Content::ContentExtractor;

my $usage = "usage: ContentExtractorDriver.pl <html file> <extract file> <Ratio>\n\t\twhere <Ratio> is one of \"Weighted\",\"Normalized\",\"Relative\",\"Smoothed\",\"Exponential\",\"Ratio\"\n\n";
@ARGV >= 2 or croak $usage;

my $tokenizer = new HTML::Content::HTMLTokenizer('TAG','WORD');

my $ranker;
if ($ARGV[2] && $ARGV[2] eq 'Weighted')
{
	$ranker = new HTML::WordTagRatio::WeightedRatio();
}
elsif($ARGV[2] && $ARGV[1] eq 'Nomalized')
{
	$ranker = new HTML::WordTagRatio::NormalizedRatio();
}
elsif($ARGV[1] && $ARGV[1] eq 'Relative')
{
	$ranker = new HTML::WordTagRatio::RelativeRatio();
}
elsif($ARGV[1] && $ARGV[1] eq 'Smoothed')
{
	$ranker = new HTML::WordTagRatio::SmoothedRatio();
}
elsif($ARGV[1] && $ARGV[1] eq 'Exponential')
{
	$ranker = new HTML::WordTagRatio::ExponentialRatio();
}
else
{
	$ranker = new HTML::WordTagRatio::Ratio();
}

my $extractor = new HTML::Content::ContentExtractor($tokenizer,$ranker,$ARGV[0],$ARGV[1]);

$extractor->Extract();