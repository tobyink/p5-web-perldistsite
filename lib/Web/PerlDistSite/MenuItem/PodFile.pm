package Web::PerlDistSite::MenuItem::PodFile;

our $VERSION = '0.001003';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

extends 'Web::PerlDistSite::MenuItem::File';

sub body_class {
	return 'page from-pod';
}

sub compile_page ( $self ) {
	my $dom = $self->project->get_template_page( $self );
	$dom->getElementsByTagName( 'body' )->shift->setAttribute( class => $self->body_class );
	my $content = $self->_pod2html( $self->raw_content );
	my $article = $dom->createElement( 'article' );
	$article->setAttribute( class => 'container' );
	$article->appendChild( $_ ) for $content->get_nodelist;
	$dom->getElementsByTagName( 'main' )->shift->appendWellBalancedChunk(
		sprintf(
			'<div class="heading container py-3"><h1 class="display-2">%s</h1></div>',
			esc_html( $self->title ),
		)
	);
	$dom->getElementsByTagName( 'main' )->shift->appendChild( $article );
	return $self->_compile_dom( $dom );
}

1;
