package Web::PerlDistSite::Compile;

use Exporter::Almighty -setup => {
	tag => {
		default => [ qw/
			write_main_scss
			write_custom_scss
			write_variables_scss
			write_pages
			project
		/ ],
	},
};
use Web::PerlDistSite::Common -lexical, -path;

sub project () {
	require Web::PerlDistSite;
	state $project = Web::PerlDistSite->load;
	return $project;
}

sub write_main_scss () {
	require Web::PerlDistSite::Component::MainScss;
	Web::PerlDistSite::Component::MainScss->new( project => project )->write;
}

sub write_custom_scss () {
	require Web::PerlDistSite::Component::CustomScss;
	Web::PerlDistSite::Component::CustomScss->new( project => project )->write;
}

sub write_variables_scss () {
	project()->write_variables_scss();
}

sub write_pages () {
	project()->write_pages();
}

1;
