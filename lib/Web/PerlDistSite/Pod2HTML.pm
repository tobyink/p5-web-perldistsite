package Web::PerlDistSite::Pod2HTML;

our $VERSION = '0.001005';

use Moo::Role;
use Web::PerlDistSite::Common -lexical, -all;
use TOBYINK::Pod::HTML;

has _link_map => (
	is       => 'lazy',
	isa      => Map[ Str, Str ],
	builder  => true,
);

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
	for my $node ( $dom->getElementsByTagName('a') ) {
		$self->_fix_pod_link( $node );
	}
	my @nodes = $dom->getElementsByTagName('body')->map( sub { shift->childNodes } );
	return XML::LibXML::NodeList->new( @nodes );
}

sub _build__link_map ( $self ) {
	my %map;
	my @items = $self->project->menu->@*;
	while ( @items ) {
		my $item = shift @items;
		if ( $item->isa( 'Web::PerlDistSite::MenuItem::Pod' ) ) {
			$map{ $item->pod } = $item->href;
		}
		push @items, @{ $item->children // [] };
	}
	return \%map;
}

sub _fix_pod_link ( $self, $element ) {
	my $map = $self->_link_map;
	my $href = $element->getAttribute( 'href' ) or return;
	
	if ( $href =~ m{^https://metacpan.org/pod/(.+)(#.+)?$} ) {
		require URI::Escape;
		my $page = $1;
		my $anchor = $2 // '';
		$page = URI::Escape::uri_unescape( $page );
		if ( defined $map->{$page} ) {
			$element->setAttribute( 'href', $map->{$page} . $anchor );
		}
	}
	return;
}

1;
