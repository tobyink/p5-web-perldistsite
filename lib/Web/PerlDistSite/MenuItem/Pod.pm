package Web::PerlDistSite::MenuItem::Pod;

our $VERSION = '0.001003';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

use Pod::Find qw( pod_where );

extends 'Web::PerlDistSite::MenuItem';
with 'Web::PerlDistSite::Pod2HTML';

has '+title' => (
	is       => 'lazy',
	default  => sub ( $s ) {
		$s->pod;
	},
);

has '+name' => (
	is       => 'lazy',
	default  => sub ( $s ) {
		$s->pod =~ s{::}{-}gr;
	},
);

has pod => (
	is       => 'ro',
	isa      => Str,
);

sub body_class {
	return 'page from-pod';
}

sub raw_content ( $self ) {
	my $where = pod_where( { -inc => true }, $self->pod );
	return path( $where )->slurp_utf8;
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

sub write_page ( $self ) {
	$self->system_path->parent->mkpath;
	$self->system_path->spew_if_changed( $self->compile_page );
}

1;
