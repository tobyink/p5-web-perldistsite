package Web::PerlDistSite::Pod2HTML;

our $VERSION = '0.001002';

use Moo::Role;
use Web::PerlDistSite::Common -lexical, -all;
use TOBYINK::Pod::HTML;

sub _pod2html ( $self, $pod ) {
	state $pod2html = TOBYINK::Pod::HTML->new(
		pretty            => true,
		code_highlighting => false,
	);
	my $dom = $pod2html->string_to_dom( $pod );
	for my $node ( $dom->getElementsByTagName('pre') ) {
		my $new_node = $dom->createElement( 'pre' );
		my $child = $new_node->addChild( $dom->createElement( 'code' ) );
		$child->appendText( $node->textContent );
		$node->replaceNode( $new_node );
	}
	my @nodes = $dom->getElementsByTagName('body')->map( sub { shift->childNodes } );
	return XML::LibXML::NodeList->new( @nodes );
}

1;
