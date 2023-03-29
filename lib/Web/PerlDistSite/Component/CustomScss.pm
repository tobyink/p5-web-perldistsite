package Web::PerlDistSite::Component::CustomScss;

our $VERSION = '0.001000';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

with 'Web::PerlDistSite::Component';

sub filename ( $self ) {
	return '_build/custom.scss';
}

sub raw_content ( $self ) {
	state $content = do { local $/ = <DATA> };
	return $content;
}

1;

__DATA__

body {
	@extend .d-flex;
	@extend .flex-column;
	@extend .min-vh-100;
}

header {
	@extend .bg-primary;
	@extend .text-light;
	.nav-link, .navbar-brand {
		@extend .text-light;
		@extend .rounded;
	}
	.nav-link:hover {
		background: darken($primary, 5%);
	}
	.dropdown-menu {
		@extend .bg-secondary;
		@extend .text-light;
		.dropdown-item {
			@extend .text-light;
		}
		.dropdown-item:hover {
			background: darken($secondary, 5%);
		}
	}
}

body.page main {
	@extend .my-4;
}

body.homepage section {
	@extend .py-5;
}

main {
	.has-sections > section {
		@extend .py-5;
	}
	.has-sections > section:nth-child(even) {
		@extend .bg-light;
		@extend .text-dark;
	}
	.has-sections > section:last-child {
		@extend .bg-white;
		@extend .text-dark;
	}
	
	pre code {
		@extend .rounded;
		display: block;
		padding: calc($spacer / 2);
		background: lighten($light, 5%) !important;
		border: 1px solid $light;
	}
}

footer {
	@extend .py-3;
	@extend .mt-auto;
	@extend .bg-dark;
	@extend .text-light;
	a:link, a:visited {
		@extend .text-light;
	}
}

$sizes: (
	25: 25%,
	50: 50%,
	75: 75%,
	100: 100%,
	60px: 60px,
	80px: 80px,
	100px: 100px,
	auto: auto
);

@each $breakpoint in map-keys($grid-breakpoints) {
	@include media-breakpoint-up($breakpoint) {
		$infix: breakpoint-infix($breakpoint, $grid-breakpoints);
		@each $prop, $abbrev in (width: w, height: h) {
			@each $size, $length in $sizes {
				.#{$abbrev}#{$infix}-#{$size} { #{$prop}: $length !important; }
			}
		}
	}
}
