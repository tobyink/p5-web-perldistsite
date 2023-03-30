package Web::PerlDistSite;
use utf8;

=pod

=encoding utf-8

=head1 NAME

Web::PerlDistSite - generate fairly flashy websites for CPAN distributions

=head1 DESCRIPTION

Basically a highly specialized static site generator.

=over

=item 1.

Use L<https://github.com/exportertiny/exportertiny.github.io> as
a starting point.

=item 2.

Run C<< make install >>

=item 3.

Edit C<< config.yaml >> to set your colour scheme, etc.

=item 4.

Edit C<< menu.yaml >> to edit your navbar.

=item 5.

Edit pages in C<< _pages >>.

=item 6.

Run C<< make clean >> and C<< make all >>.

=item 7.

Upload your site somewhere.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-web-perldistsite/issues>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

our $VERSION = '0.001001';

use Web::PerlDistSite::MenuItem ();
use HTML::HTML5::Parser ();

has root => (
	is       => 'ro',
	isa      => PathTiny,
	required => true,
	coerce   => true,
);

has root_url => (
	is       => 'rwp',
	isa      => Str,
	default  => '/',
);

has dist_dir => (
	is       => 'lazy',
	isa      => PathTiny,
	coerce   => true,
	builder  => sub ( $s ) { $s->root->child( 'docs' ) },
);

has name => (
	is       => 'ro',
	isa      => Str,
	required => true,
);

has abstract => (
	is       => 'ro',
	isa      => Str,
	required => true,
);

has abstract_html => (
	is       => 'lazy',
	isa      => Str,
	default  => sub ( $s ) { esc_html( $s->abstract ) },
);

has issues => (
	is       => 'ro',
	isa      => Str,
);

has copyright => (
	is       => 'ro',
	isa      => Str,
);

has github => (
	is       => 'ro',
	isa      => Str,
);

has sponsor => (
	is       => 'ro',
	isa      => HashRef,
);

has theme => (
	is      => 'ro',
	isa     => HashRef->of( Str ),
);

has codestyle => (
	is       => 'ro',
	isa      => Str,
	default  => 'github',
);

has menu => (
	is      => 'ro',
	isa      => ArrayRef->of(
		InstanceOf
			->of( 'Web::PerlDistSite::MenuItem' )
			->plus_constructors( HashRef, 'from_hashref' )
	),
	coerce   => true,
);

has homepage => (
	is       => 'ro',
	isa      => HashRef,
	default  => sub ( $s ) {
		return {
			animation => 'waves1',
		}
	},
);


sub load ( $class, $filename='config.yaml' ) {
	my $data = YAML::PP::LoadFile( $filename );
	$data->{root} //= path( $filename )->absolute->parent;
	$data->{menu} //= YAML::PP::LoadFile( $data->{root}->child( 'menu.yaml' ) );
	$class->new( $data->%* );
}

sub footer ( $self ) {
	my @sections;
	
	if ( $self->github ) {
		push @sections, sprintf(
			'<h2>Contributing</h2>
			<p>%s is an open source project <a href="%s">hosted on Github</a> —
			open an issue if you have an idea or find a bug.</p>',
			esc_html( $self->name ),
			esc_html( $self->github ),
		);
		if ( $self->github =~ m{^https://github.com/(.+)$} ) {
			my $path = $1;
			$sections[-1] .= sprintf(
				'<p><img alt="GitHub Repo stars"
				src="https://img.shields.io/github/stars/%s?style=social"></p>',
				$path,
			);
		}
	}
	
	if ( $self->sponsor ) {
		push @sections, sprintf(
			'<h2>Sponsoring</h2>
			<p>%s</p>',
			esc_html( $self->sponsor->{html} ),
		);
		if ( $self->sponsor->{href} ) {
			$sections[-1] .= sprintf(
				'<p><a class="btn btn-light" href="%s"><span class="text-dark">Sponsor</span></a></p>',
				esc_html( $self->sponsor->{href} ),
			);
		}
	}
	
	my $width = int( 12 / @sections );
	my @html;
	push @html, '<div class="container">';
	push @html, '<div class="row">';
	for my $section ( @sections ) {
		push @html, "<div class=\"col-12 col-lg-$width\">$section</div>";
	}
	if ( $self->copyright ) {
		push @html, '<div class="col-12 text-center pt-3">';
		push @html, sprintf( '<p>%s</p>', esc_html( $self->copyright ) );
		push @html, '</div>';
	}
	push @html, '</div>';
	push @html, '</div>';
	return join qq{\n}, @html;
}

sub navbar ( $self, $active_item ) {
	my @html;
	push @html, '<nav class="navbar navbar-expand-lg">';
	push @html, '<div class="container">';
	push @html, sprintf( '<a class="navbar-brand" href="%s">%s</a>', $self->root_url, $self->name );
	push @html, '<button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">';
	push @html, '<span class="navbar-toggler-icon"></span>';
	push @html, '</button>';
	push @html, '<div class="collapse navbar-collapse" id="navbarSupportedContent">';
	push @html, '<ul class="navbar-nav ms-auto mb-2 mb-lg-0">';
	push @html, map $_->nav_item( $active_item ), $self->menu->@*;
	push @html, '</ul>';
	push @html, '</div>';
	push @html, '</div>';
	push @html, '</nav>';
	return join qq{\n}, @html;
}

sub BUILD ( $self, $args ) {
	$_->project( $self ) for $self->menu->@*;
	$self->root_url( $self->root_url . '/' ) unless $self->root_url =~ m{/$};
}

sub write_pages ( $self ) {
	for my $item ( $self->menu->@* ) {
		$item->write_pages;
	}
	$self->write_homepage;
}

sub write_variables_scss ( $self ) {
	my $scss = '';
	for my $key ( sort keys $self->theme->%* ) {
		$scss .= sprintf( '$%s: %s;', $key, $self->theme->{$key} ) . "\n";
	}
	$self->root->child( '_build/variables.scss' )->spew_if_changed( $scss );
}

sub write_homepage ( $self ) {
	require Web::PerlDistSite::MenuItem::Homepage;
	my $page = Web::PerlDistSite::MenuItem::Homepage->new( project => $self );
	$page->write_pages;
}

sub get_template_page ( $self, $item=undef ) {
	state $template = do {
		local $/;
		my $html = <DATA>;
		$html =~ s[\{\{\s*\$root\s*\}\}]{$self->root_url}ge;
		$html =~ s[\{\{\s*\$codestyle\s*\}\}]{$self->codestyle}ge;
		$html;
	};
	
	state $p = HTML::HTML5::Parser->new;
	my $dom = $p->parse_string( $template );
	
	my $navbar = $p->parse_balanced_chunk( $self->navbar( $item ) );
	$dom->getElementsByTagName( 'header' )->shift->appendChild( $navbar );
	
	my $footer = $p->parse_balanced_chunk( $self->footer );
	$dom->getElementsByTagName( 'footer' )->shift->appendChild( $footer );
	
	$dom->getElementsByTagName( 'title' )->shift->appendText( $item ? $item->page_title : $self->name );
	
	return $dom;
}

1;

__DATA__
<html>
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<title></title>
		<link href="{{ $root }}assets/styles/main.css" rel="stylesheet">
		<link rel="stylesheet" href="//unpkg.com/@highlightjs/cdn-assets@11.7.0/styles/{{ $codestyle }}.min.css">
	</head>
	<body>
		<header></header>
		<main></main>
		<div style="height: 150px; overflow: hidden;"><svg viewBox="0 0 500 150" preserveAspectRatio="none" style="height: 100%; width: 100%;"><path d="M0.00,49.98 C138.82,121.67 349.20,-49.98 500.00,49.98 L500.00,150.00 L0.00,150.00 Z" style="stroke: none; fill: rgba(var(--bs-dark-rgb), 1);"></path></svg></div>
		<footer></footer>
		<script src="{{ $root }}assets/scripts/bootstrap.bundle.min.js"></script>
		<script src="//kit.fontawesome.com/6d700b1a29.js" crossorigin="anonymous"></script>
		<script src="//unpkg.com/@highlightjs/cdn-assets@11.7.0/highlight.min.js"></script>
		<script>
		window.addEventListener( 'scroll', function () {
			const scroll = document.documentElement.scrollTop;
			if ( scroll > 75 ) {
				document.body.classList.add( 'is-scrolled' );
				document.body.classList.remove( 'at-top' );
			}
			else if ( scroll < 25 ) {
				document.body.classList.remove( 'is-scrolled' );
				document.body.classList.add( 'at-top' );
			}
		} );
		document.body.classList.add( 'at-top' );
		hljs.highlightAll();
		</script>
	</body>
</html>