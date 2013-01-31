package HTML::Content::Extractor;

use strict;
use vars qw($AUTOLOAD $VERSION $ABSTRACT @ISA @EXPORT);

BEGIN {
	$VERSION = 0.12;
	$ABSTRACT = "Recieving main text of publication from HTML page and main media content that is bound to the text";

	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw();
};

bootstrap HTML::Content::Extractor $VERSION;

use DynaLoader ();
use Exporter ();

1;

__END__

=head1 NAME

HTML::Content::Extractor - Recieving a main text of publication from HTML page and main media content that is bound to the text

=head1 SYNOPSIS

 my $obj = HTML::Content::Extractor->new();
 $obj->analyze($html);
 
 my $main_text   = $obj->get_main_text();
 my $main_images = $obj->get_main_images();
 
 print $main_text, "\n\n";
 
 print "Images:\n";
 foreach my $url (@$main_images) {
	print $url, "\n";
 }

=head1 DESCRIPTION

This module analyzes an HTML document and extracts the main text (for example front page article contents on the news site) and all related images.

=head1 METHODS

=head2 new

 my $obj = HTML::Content::Extractor->new();

Creates and prepares the structure for the subsequent analysis and parsing HTML.

=head2 analyze

 $obj->analyze($html);
    
Creates an HTML document tree and analyzes it.

=head2 get_main_text

 # UTF-8
 my $main_text = $obj->get_main_text(1);
 # or not
 my $main_text = $obj->get_main_text(0);
 # default UTF-8 is on

Return plain text.

=head2 get_main_images

 # UTF-8
 my $main_images = $obj->get_main_images(1);
 # or not
 my $main_images = $obj->get_main_images(0);
 # default UTF-8 is on

Returns ARRAY with pictures URL.

=head1 DESTROY

 undef $obj;

Cleaning of all internal structures (HTML tree and other)

=head1 AUTHOR

Alexander Borisov <lex.borisov@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexander Borisov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
