#!/usr/bin/perl
# POD {{{
=head1 NAME

pp - Perl Pipe helper

=head1 SYNOPSIS

	pp <regexp...>

=head1 QUICK EXAMPLES

	# Perlish grep of STDIN
	pp m/foo/

	# Replace foo -> bar
	pp s/foo/bar

	# Combine the above examples, filter 'foo' and convert result into uppercase
	pp m/foo/ s/b../\U\1\E/

	# Extract only the matching portions from the input stream
	pp m/^(b..)/

	# Same as above but lazily assume brackets around everything.
	pp -c m/b../

	# Run STDIN though Perl function 'ucfirst'
	pp ucfirst

	# Run STDIN though the alias 'basename' specified in either /etc/pprc or ~/.pprc
	pp basename

=head1 OPTIONS

=over 8

=item B<-c>

=item B<--capture>

Only ouputs the matching portion of the final matching m// expression.
This is effectivly the same as enclosing the final m// expression inside brackets.

These two functions are the same:

	echo 'foo bar baz' | pp m/(b..)/
	echo 'foo bar baz' | pp -c m/b../

In each case only the bracketed portion of the expression is returned

=item B<-i>

=item B<--nocase>

Dont care about case sensitivity.
This is effectivly the same as ending every expression with the '/i' flag.

=item B<-j [string]>

=item B<--join [string]>

When using m// with brackets or in capture (-c) mode and the expression has multiple captures, this specifies the speration character.
If unspecified the detault is a space.

For example:
	
	echo 'foo bar baz' | pp m/(b..) (b..)/ # Outputs 'bar baz'
	echo 'foo bar baz' | pp m/(b..) (b..)/ -j 'XXXX' # Outputs 'barXXXXbaz'

=item B<-0>

=item B<--print0>

Output a null character at the end of each line instead of the usual line feed.
This argument makes it easier to pass output onto xargs in a safe way.
e.g.

	ls | pp m/foo/ -0 | xargs -0 echo

Will output all files matching 'foo' in way that ensures files with spaces in their names will not be ruined.

=item B<-v>

=item B<--verbose>

Be more verbose when outputting information to STDERR.
Specify multiple times to increase verbosity.
This can be particularly helpful when trying to debug why something isnt matching.

=back

=head1 DESCRIPTION

Run various output though a series of Perl regexps.
This is really just a helper for Perl regular expressions where we apply rules based on the usual DWIM (Do What I Mean) philosophy. See the EXAMPLES section for practical info.

=head1 TYPES OF EXPRESSIONS

PP supports a variety of regular expresions. They all follow the usual Perl format but can supply output in differnt ways.
Generally speaking PP will try to follow the principle of least astonishment whereby the regexp I<should> return what you wanted rather than what the technical spec actually specifies.

=over

=item B<Matching (m//)>

	m/foo/
	m/foo/i
	/foo/
	/foo/i

Match 'foo' in the incomming stream. If 'i' is specified (or -i is turned on) this is done case insensitively.
The output is the entire line of input - this is effectivly the same as a Perlish version of grep.

=item B<Capturing - matching with brackets (m/()/)>

	m/(foo)/
	m/(foo)/i
	/(foo)/
	/(foo)/i

Similar to the regular m// usage when any brackets are present in the capture string PP goes into capture mode (same as specifying -c for the regular m// syntax).
In capture mode only the matching portion of the string is output. The the above strings the only possible output can be 'foo' (or however its cased in the '/i' flag examples.

=item B<Subsitution (s///)>

	s/foo/bar/
	s/foo/bar/i

Replaces any matched portions in the left and side with those in the right in the form of a regular substitution.
This can be combined with the positional indicators (e.g. \1) to do something useful with the input stream.

For example the following convers to upper case:

	s/.*/\U\1/E/

=item B<Perl Functions>

	lc
	lcfirst
	length
	reverse
	uc
	ucfirst

=item B<Convenience functions>

	These functions may require additional Perl modules to be installed.

	human (Number::Bytes::Human->format_bytes)

Runs the input stream though the named Perl function e.g.

	pp ucfirst

Will capitalize all first letters in the input stream.

This functionality is really just a stub and might be expanded into full CPAN module integration later on.


=item B<Aliasing>

Aliasing works in exactly the same way as the above functions except the actual operation of the alias is first looked up in the files specified in the FILES section.

So
	pp basename

Makes pp look up what 'basename' specifies (hopefully something like 's/^(.*\/)?(.*?)$/\2/g') and simply replaces it with that value.

See the example .pprc file included with this package for some handy examples.

=back

=head1 FILES

=over 8

=item B</etc/pprc>

PP config file for all users.

=item B<.pprc>

PP config file for the local user.

=back

=head1 CONFIG

The /etc/pprc and .pprc files will be processed to determine PP's configuration, the latter file taking precedence.

An example layout for these files is as follows

	[ALIASES]
	trim = s/^\s*(.*)$/\1
	foobar = s/foo/bar/

In the above 'trim' is defined using the relevent regular expressions specified. These are used as if the user were entering these manually.

So:

	pp trim

Actually becomes

	pp s/^\s*(.*)$/\1

=head1 EXAMPLES

=over

=item B<pp s/foo/bar/>

Replace 'foo' with 'bar' on the input stream.

=item B<echo 'foo-bar-baz' | pp m/BAR/i>

Works just like grep with a Perl regexp, match the word BAR in a case insensitive manner (same as -i).

=item B<echo 'foo-bar-baz' | pp m/b../>

Same as above, this time matching only lines containing '/b../'.

=item B<echo 'foo-bar-baz' | pp m/b../ s/b(..)/\1/>

Combines the above two examples.

=item B<echo 'foo-bar-baz' | pp m/(b..)/>

Returns only 'bar' on the output stream. This is effectively the same as 's/.*(b..).*/\1/g'

=item B<echo 'foo-bar-baz' | pp -c m/b../>

Same result as above, when '-c' is specified PP acts as if brackets were around everything.

=item B<echo 'foo-bar-baz' | pp m/(b..)/ s/.*/Prefix:\1:Suffix/>

Captures only 'bar' from the above example but replaces it with 'Prefix:bar:Suffix'

=item B<echo 'foo-bar-baz' | pp uc'>

Alternative 'cheap' way of doing capitalization using Perls in built 'uc' function.

=back

=head1 BUGS

Quite probably.

Please report to https://github.com/hash-bang/PP when found.

=head1 AUTHOR

Matt Carter <m@ttcarter.com>

=cut
# }}} POD

package pp;
our $VERSION = '0.1.4';

# Header {{{
use Config::IniFiles;
use IO::Handle;
use Getopt::Long;
Getopt::Long::Configure('bundling', 'ignorecase_always', 'pass_through');
STDERR->autoflush(1); # } Flush the output DIRECTLY to the output buffer without caching
STDOUT->autoflush(1); # }

use Data::Dumper; # FIXME: Debug

use constant { # Declare match types
	MATCH => 0,
	SUBST => 1,
	FUNCT => 2,
};
# }}} Header

# Functions {{{
sub fatal {
	# Print an error message and fatally die
	print STDERR @_, "\n";
	exit 1;
}

sub say {
	# Print a message to STDERR based on the verbosity level
	our $verbose;
	my $verbosity = shift;
	print STDERR @_, "\n" if ($verbose >= $verbosity);
}

# Rather silly import of standard Perl functions so we can use referers (e.g. &$func) later on
sub lc { lc }
sub lcfirst { lcfirst }
sub length { length }
sub reverse { reverse }
sub uc { uc }
sub ucfirst { ucfirst }

# Convenience wrappers
sub human {
	use Number::Bytes::Human qw/format_bytes/;
	return format_bytes($_);
}

# }}} Functions 

# Config loading {{{
my $cfgfile;
if (-e "/etc/pprc") {
	$cfgfile = "/etc/pprc";
} elsif (-e "$ENV{HOME}/.pprc") {
	$cfgfile = "$ENV{HOME}/.pprc";
} else {
	say(1, "No PPRC file could be found at either /etc/pprc or \$HOME/.pprc");
}

my $cfg = Config::IniFiles->new(
	-file => ($cfgfile ? $cfgfile : \*DATA), # Read defaults from __DATA__ section if we cant find a default file.
	-default => 'aliases',
	-fallback => 'aliases',
	-nocase => 1,
	-allowempty => 1,
	-handle_trailing_comment => 1,
);
# }}} Config loading

# Command line processing {{{
our $verbose = 0;
my $nocase, $print0;
my $join = ' ';
GetOptions(
	# Global options
	'capture|c' => \$capture,
	'join|j=s' => \$join,
	'nocase|i' => \$nocase,
	'print0|0' => \$print0,
	'verbose|v+' => \$verbose,
);

@regs = map {
	my $type, $qr;
	say(2, "Processing regexp '$_'");
	if (my $alias = $cfg->val('aliases', $_, 0)) { # Is an alias
		say(2, "Import alias '$_' as '$alias'");
		$_ = $alias;
	}
	if (my($exp, $flags) = (m{^m?/(.*?)(?:(?<=[^\\])/([a-z]*))?$})) { # Match syntax FIXME: This is a silly way of identifying a m//
		$exp = "($exp)" if $capture; # Force brackets around expression if capture mode is on
		$_ = [
			MATCH,
			($nocase or $flags =~ /i/) ? qr/$exp/i : qr/$exp/, # FIXME: There must be a better way of doing this on the fly. Why doesnt Perl seem to support qr/$foo/$bar ?,
			($exp =~ /\(.*\)/), # Capture mode or the expression has brackets - do a capture
		];
	} elsif (my($exp, $replace, $flags) = (m{^s/(.*?)(?<=[^\\])/(.*?)(?:/([a-z]*))?$})) { # Substitution syntax FIXME: This is a silly way
		$_ = [
			SUBST,
			($nocase or $flags =~ /i/) ? qr/$exp/i : qr/$exp/, # FIXME: See above
			$replace,
		];
	} elsif (defined &{$_}) { # Use Perl function
		$_ = [
			FUNCT,
			$_,
		];
	} else {
		print "Unknown operation type: '$_'\n";
		exit 1;
	}

} @ARGV;
# }}} Command line processing

LINE: while (<STDIN>) {
	chomp;
	foreach my $reg (@regs) {
		my ($type, $regexp, $replacement) = @{$reg};
		if ($type == MATCH) {
			say(2, "Try to match line '$_' against m/$regexp/...");
			next LINE unless my @matches = (m/$regexp/);
			if ($replacement) {
				say(2, "Capture mode for m/$regexp/ triggered");
				$_ = join $join, @matches;
			} else { # Regular 'grep' mode
				say(2, "Matched. Continuing...");
			}
		} elsif ($type == SUBST) {
			say(2, "Try to replace line '$_' against s/$regexp/ with '$replacement'");
			$replacement =~ s/\\([0-9]+)/\${\1}/g; # Replace old style \1 with ${1}
			$replacement = '"' . $replacement . '"'; # Escape the replacement string to preserve the variable interpolation
			s/$regexp/$replacement/ee;
		} elsif ($type == FUNCT) {
			say(2, "Running '$_' though function '$regexp'");
			$_ = &$regexp($_);
		}
	}
	say(3, "Output: '$_'\n");
	print $_,($print0 ? "\000" : "\n");
}

__DATA__
[ALIASES]
basename = s/^(.*\/)?(.*?)$/\2/g
dirname = s/^(.*)\/(.*?)?$/\1/g
trim = s/^\s*(.*?)\s*$/\1/g
