package Web::PerlDistSite::MenuItem::Pod;

our $VERSION = '0.001006';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

use Pod::Find qw( pod_where );

extends 'Web::PerlDistSite::MenuItem';
with 'Web::PerlDistSite::MenuItem::_PodCommon';

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

sub write_page ( $self ) {
	$self->system_path->parent->mkpath;
	$self->system_path->spew_if_changed( $self->compile_page );
}

1;
