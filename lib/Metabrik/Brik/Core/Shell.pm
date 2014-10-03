#
# $Id$
#
# core::shell Brik
#
package Metabrik::Brik::Core::Shell;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub declare_attributes {
   return {
      echo => [],
      _shell => [],
   };
}

{
   no warnings;   # Avoid redefine warnings

   # We redefine some accessors so we can write the value to Ext::Shell

   *echo = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell echo attribute only when is has been populated
         if (defined($self->_shell)) {
            return $self->_shell->echo($self->{echo} = $value);
         }

         return $self->{echo} = $value;
      }

      return $self->{echo};
   };

   *debug = sub {
      my $self = shift;
      my ($value) = @_;

      if (defined($value)) {
         # set shell debug attribute only when is has been populated
         if (defined($self->_shell)) {
            return $self->_shell->debug($self->{debug} = $value);
         }

         return $self->{debug} = $value;
      }

      return $self->{debug};
   };
}

sub require_modules {
   return {
   };
}

sub help {
   return {
      'set:echo' => '<0|1>',
      'run:splash' => '',
      'run:title' => '<title>',
      'run:cmd' => '<cmd>',
      'run:cmdloop' => '',
      'run:script' => '<script>',
      'run:shell' => '<command> [ <arg1:arg2:..:argN> ]',
      'run:system' => 'system <command> [ <arg1:arg2:..:argN> ]',
      'run:history' => '[ <number> ]',
      'run:write_history' => '',
      'run:cd' => '[ <path> ]',
      'run:pwd' => '',
      'run:pl' => '<code>',
      'run:su' => '',
      'run:help' => '[ <cmd> ]',
      'run:show' => '',
      'run:use' => '<brik>',
      'run:set' => '<brik> <attribute> <value>',
      'run:get' => '[ <brik> ] [ <attribute> ]',
      'run:run' => '<brik> <command> [ <arg1:arg2:..:argN> ]',
      'run:exit' => '',
   };
}

sub default_values {
   return {
      echo => 1,
   };
}

sub init {
   my $self = shift->SUPER::init(
      @_,
   ) or return 1; # Init already done

   $self->debug && $self->log->debug("init: start");

   $Metabrik::Ext::Shell::CTX = $self->context;

   my $shell = Metabrik::Ext::Shell->new;
   $shell->echo($self->echo);
   $shell->debug($self->debug);

   $self->_shell($shell);

   $self->debug && $self->log->debug("init: done");

   return $self;
}

sub splash {
   my $self = shift;

   # ASCII art courtesy: http://patorjk.com/software/taag/#p=testall&f=Graffiti&t=MetabriK
   print<<EOF

        ███▄ ▄███▓▓█████▄▄▄█████▓ ▄▄▄       ▄▄▄▄    ██▀███   ██▓ ██ ▄█▀
       ▓██▒▀█▀ ██▒▓█   ▀▓  ██▒ ▓▒▒████▄    ▓█████▄ ▓██ ▒ ██▒▓██▒ ██▄█▒
       ▓██    ▓██░▒███  ▒ ▓██░ ▒░▒██  ▀█▄  ▒██▒ ▄██▓██ ░▄█ ▒▒██▒▓███▄░
       ▒██    ▒██ ▒▓█  ▄░ ▓██▓ ░ ░██▄▄▄▄██ ▒██░█▀  ▒██▀▀█▄  ░██░▓██ █▄
       ▒██▒   ░██▒░▒████▒ ▒██▒ ░  ▓█   ▓██▒░▓█  ▀█▓░██▓ ▒██▒░██░▒██▒ █▄
       ░ ▒░   ░  ░░░ ▒░ ░ ▒ ░░    ▒▒   ▓▒█░░▒▓███▀▒░ ▒▓ ░▒▓░░▓  ▒ ▒▒ ▓▒
       ░  ░      ░ ░ ░  ░   ░      ▒   ▒▒ ░▒░▒   ░   ░▒ ░ ▒░ ▒ ░░ ░▒ ▒░
       ░      ░      ░    ░        ░   ▒    ░    ░   ░░   ░  ▒ ░░ ░░ ░
              ░      ░  ░              ░  ░ ░         ░      ░  ░  ░
                                                 ░
EOF
;

   return 1;
}

sub title {
   my $self = shift;

   $self->_shell->run_title(@_);

   return 1;
}

sub system {
   my $self = shift;

   $self->_shell->run_system(@_);

   return 1;
}

sub history {
   my $self = shift;

   $self->_shell->run_history(@_);

   return 1;
}

sub write_history {
   my $self = shift;

   $self->_shell->run_write_history(@_);

   return 1;
}

sub cd {
   my $self = shift;

   $self->_shell->run_cd(@_);

   return 1;
}

sub pl {
   my $self = shift;

   $self->_shell->run_pl(@_);

   return 1;
}

sub su {
   my $self = shift;

   $self->_shell->run_su(@_);

   return 1;
}

sub show {
   my $self = shift;

   $self->_shell->run_show(@_);

   return 1;
}

sub use {
   my $self = shift;

   $self->_shell->run_use(@_);

   return 1;
}

sub set {
   my $self = shift;

   $self->_shell->run_set(@_);

   return 1;
}

sub get {
   my $self = shift;

   $self->_shell->run_get(@_);

   return 1;
}

sub run {
   my $self = shift;

   $self->_shell->run_run(@_);

   return 1;
}

sub exit {
   my $self = shift;

   $self->_shell->run_exit(@_);

   return 1;
}

sub cmd {
   my $self = shift;

   $self->_shell->cmd(@_);

   return 1;
}

sub cmdloop {
   my $self = shift;

   $self->_shell->cmdloop(@_);

   return 1;
}

sub script {
   my $self = shift;

   $self->_shell->run_script(@_);

   return 1;
}

1;

#
# Term::Shell package
#
package CPAN::Term::Shell;

use strict;
use warnings;

use 5.008;

use Data::Dumper;
use Term::ReadLine;

use vars qw($VERSION);

$VERSION = '0.06';

#=============================================================================
# Term::Shell API methods
#=============================================================================
sub new {
    my $cls = shift;
    my $o = bless {
	term	=> eval {
	    # Term::ReadKey throws ugliness all over the place if we're not
	    # running in a terminal, which we aren't during "make test", at
	    # least on FreeBSD. Suppress warnings here.
	    local $SIG{__WARN__} = sub { };
	    Term::ReadLine->new('shell');
	} || undef,
    }, ref($cls) || $cls;

    # Set up the API hash:
    $o->{command} = {};
    $o->{API} = {
	args		=> \@_,
	case_ignore	=> ($^O eq 'MSWin32' ? 1 : 0),
	check_idle	=> 0,	# changing this isn't supported
	class		=> $cls,
	command		=> $o->{command},
	cmd		=> $o->{command}, # shorthand
	match_uniq	=> 1,
	pager		=> $ENV{PAGER} || 'internal',
	readline	=> eval { $o->{term}->ReadLine } || 'none',
	script		=> (caller(0))[1],
	version		=> $VERSION,
    };

    # Note: the rl_completion_function doesn't pass an object as the first
    # argument, so we have to use a closure. This has the unfortunate effect
    # of preventing two instances of Term::ReadLine from coexisting.
    my $completion_handler = sub {
	$o->rl_complete(@_);
    };
    if ($o->{API}{readline} eq 'Term::ReadLine::Gnu') {
	my $attribs = $o->{term}->Attribs;
	$attribs->{completion_function} = $completion_handler;
    }
    elsif ($o->{API}{readline} eq 'Term::ReadLine::Perl') {
	$readline::rl_completion_function =
	$readline::rl_completion_function = $completion_handler;
    }
    $o->find_handlers;
    $o->init;
    $o;
}

sub DESTROY {
    my $o = shift;
    $o->fini;
}

sub cmd {
    my $o = shift;
    $o->{line} = shift;
    if ($o->line =~ /\S/) {
	my ($cmd, @args) = $o->line_parsed;
	$o->run($cmd, @args);
	unless ($o->{command}{run}{found}) {
	    my @c = sort $o->possible_actions($cmd, 'run');
	    if (@c and $o->{API}{match_uniq}) {
		print $o->msg_ambiguous_cmd($cmd, @c);
	    }
	    else {
		print $o->msg_unknown_cmd($cmd);
	    }
	}
    }
    else {
	$o->run('');
    }
}

sub stoploop { $_[0]->{stop}++ }
sub cmdloop {
    my $o = shift;
    $o->{stop} = 0;
    $o->preloop;
    while (defined (my $line = $o->readline($o->prompt_str))) {
	$o->cmd($line);
	last if $o->{stop};
    }
    $o->postloop;
}
*mainloop = \&cmdloop;

sub readline {
    my $o = shift;
    my $prompt = shift;
    return $o->{term}->readline($prompt)
	if $o->{API}{check_idle} == 0
	    or not defined $o->{term}->IN;

    # They've asked for idle-time running of some user command.
    local $Term::ReadLine::toloop = 1;
    local *Tk::fileevent = sub {
	my $cls = shift;
	my ($file, $boring, $callback) = @_;
	$o->{fh} = $file;	# save the filehandle!
	$o->{cb} = $callback;	# save the callback!
    };
    local *Tk::DoOneEvent = sub {
	# We'll totally cheat and do a select() here -- the timeout will be
	# $o->{API}{check_idle}; if the handle is ready, we'll call &$cb;
	# otherwise we'll call $o->idle(), which can do some processing.
	my $timeout = $o->{API}{check_idle};
	use IO::Select;
	if (IO::Select->new($o->{fh})->can_read($timeout)) {
	    # Input is ready: stop the event loop.
	    $o->{cb}->();
	}
	else {
	    $o->idle;
	}
    };
    $o->{term}->readline($prompt);
}

sub term { $_[0]->{term} }

# These are likely candidates for overriding in subclasses
sub init { }		# called last in the ctor
sub fini { }		# called first in the dtor
sub preloop { }
sub postloop { }
sub precmd { }
sub postcmd { }
sub prompt_str { 'shell> ' }
sub idle { }
sub cmd_prefix { '' }
sub cmd_suffix { '' }

#=============================================================================
# The pager
#=============================================================================
sub page {
    my $o         = shift;
    my $text      = shift;
    my $maxlines  = shift || $o->termsize->{rows};
    my $pager     = $o->{API}{pager};

    # First, count the number of lines in the text:
    my $lines = ($text =~ tr/\n//);

    # If there are fewer lines than the page-lines, just print it.
    if ($lines < $maxlines or $maxlines == 0 or $pager eq 'none') {
	print $text;
    }
    # If there are more, page it, either using the external pager...
    elsif ($pager and $pager ne 'internal') {
	require File::Temp;
	my ($handle, $name) = File::Temp::tempfile();
	select((select($handle), $| = 1)[0]);
	print $handle $text;
	close $handle;
	system($pager, $name) == 0
	    or print <<END;
Warning: can't run external pager '$pager': $!.
END
	unlink $name;
    }
    # ... or the internal one
    else {
	my $togo = $lines;
	my $line = 0;
	my @lines = split '^', $text;
	while ($togo > 0) {
	    my @text = @lines[$line .. $#lines];
	    my $ret = $o->page_internal(\@text, $maxlines, $togo, $line);
	    last if $ret == -1;
	    $line += $ret;
	    $togo -= $ret;
	}
	return $line;
    }
    return $lines
}

sub page_internal {
    my $o           = shift;
    my $lines       = shift;
    my $maxlines    = shift;
    my $togo        = shift;
    my $start       = shift;

    my $line = 1;
    while ($_ = shift @$lines) {
	print;
	last if $line >= ($maxlines - 1); # leave room for the prompt
	$line++;
    }
    my $lines_left = $togo - $line;
    my $current_line = $start + $line;
    my $total_lines = $togo + $start;

    my $instructions;
    if ($o->have_readkey) {
	$instructions = "any key for more, or q to quit";
    }
    else {
	$instructions = "enter for more, or q to quit";
    }

    if ($lines_left > 0) {
	local $| = 1;
	my $l = "---line $current_line/$total_lines ($instructions)---";
	my $b = ' ' x length($l);
	print $l;
	my $ans = $o->readkey;
	print "\r$b\r" if $o->have_readkey;
	print "\n" if $ans =~ /q/i or not $o->have_readkey;
	$line = -1 if $ans =~ /q/i;
    }
    $line;
}

#=============================================================================
# Run actions
#=============================================================================
sub run {
    my $o = shift;
    my $action = shift;
    my @args = @_;
    $o->do_action($action, \@args, 'run')
}

sub complete {
    my $o = shift;
    my $action = shift;
    my @args = @_;
    my @compls = $o->do_action($action, \@args, 'comp');
    return () unless $o->{command}{comp}{found};
    return @compls;
}

sub help {
    my $o = shift;
    my $topic = shift;
    my @subtopics = @_;
    $o->do_action($topic, \@subtopics, 'help')
}

sub summary {
    my $o = shift;
    my $topic = shift;
    $o->do_action($topic, [], 'smry')
}

#=============================================================================
# Manually add & remove handlers
#=============================================================================
sub add_handlers {
    my $o = shift;
    for my $hnd (@_) {
	next unless $hnd =~ /^(run|help|smry|comp|catch|alias)_/o;
	my $t = $1;
	my $a = substr($hnd, length($t) + 1);
	# Add on the prefix and suffix if the command is defined
	if (length $a) {
	    substr($a, 0, 0) = $o->cmd_prefix;
	    $a .= $o->cmd_suffix;
	}
	$o->{handlers}{$a}{$t} = $hnd;
	if ($o->has_aliases($a)) {
	    my @a = $o->get_aliases($a);
	    for my $alias (@a) {
		substr($alias, 0, 0) = $o->cmd_prefix;
		$alias .= $o->cmd_suffix;
		$o->{handlers}{$alias}{$t} = $hnd;
	    }
	}
    }
}

sub add_commands {
    my $o = shift;
    while (@_) {
	my ($cmd, $hnd) = (shift, shift);
	$o->{handlers}{$cmd} = $hnd;
    }
}

sub remove_handlers {
    my $o = shift;
    for my $hnd (@_) {
	next unless $hnd =~ /^(run|help|smry|comp|catch|alias)_/o;
	my $t = $1;
	my $a = substr($hnd, length($t) + 1);
	# Add on the prefix and suffix if the command is defined
	if (length $a) {
	    substr($a, 0, 0) = $o->cmd_prefix;
	    $a .= $o->cmd_suffix;
	}
	delete $o->{handlers}{$a}{$t};
    }
}

sub remove_commands {
    my $o = shift;
    for my $name (@_) {
	delete $o->{handlers}{$name};
    }
}

*add_handler = \&add_handlers;
*add_command = \&add_commands;
*remove_handler = \&remove_handlers;
*remove_command = \&remove_commands;

#=============================================================================
# Utility methods
#=============================================================================
sub termsize {
    my $o = shift;
    my ($rows, $cols) = (24, 78);

    # Try several ways to get the terminal size
  TERMSIZE:
    {
	my $TERM = $o->{term};
	last TERMSIZE unless $TERM;

	my $OUT = $TERM->OUT;

	if ($TERM and $o->{API}{readline} eq 'Term::ReadLine::Gnu') {
	    ($rows, $cols) = $TERM->get_screen_size;
	    last TERMSIZE;
	}

	if ($^O eq 'MSWin32' and eval { require Win32::Console }) {
	    Win32::Console->import;
	    # Win32::Console's DESTROY does a CloseHandle(), so save the object:
	    $o->{win32_stdout} ||= Win32::Console->new(STD_OUTPUT_HANDLE());
	    my @info = $o->{win32_stdout}->Info;
	    $cols = $info[7] - $info[5] + 1; # right - left + 1
	    $rows = $info[8] - $info[6] + 1; # bottom - top + 1
	    last TERMSIZE;
	}

	if (eval { require Term::Size }) {
	    my @x = Term::Size::chars($OUT);
	    if (@x == 2 and $x[0]) {
		($cols, $rows) = @x;
		last TERMSIZE;
	    }
	}

	if (eval { require Term::Screen }) {
	    my $screen = Term::Screen->new;
	    ($rows, $cols) = @$screen{qw(ROWS COLS)};
	    last TERMSIZE;
	}

	if (eval { require Term::ReadKey }) {
	    ($cols, $rows) = eval {
		local $SIG{__WARN__} = sub {};
		Term::ReadKey::GetTerminalSize($OUT);
	    };
	    last TERMSIZE unless $@;
	}

	if ($ENV{LINES} or $ENV{ROWS} or $ENV{COLUMNS}) {
	    $rows = $ENV{LINES} || $ENV{ROWS} || $rows;
	    $cols = $ENV{COLUMNS} || $cols;
	    last TERMSIZE;
	}

	{
	    local $^W;
	    local *STTY;
	    if (open (STTY, "stty size |")) {
		my $l = <STTY>;
		($rows, $cols) = split /\s+/, $l;
		close STTY;
	    }
	}
    }

    return { rows => $rows, cols => $cols};
}

sub readkey {
    my $o = shift;
    $o->have_readkey unless $o->{readkey};
    $o->{readkey}->();
}

sub have_readkey {
    my $o = shift;
    return 1 if $o->{have_readkey};
    my $IN = $o->{term}->IN;
    if (eval { require Term::InKey }) {
	$o->{readkey} = \&Term::InKey::ReadKey;
    }
    elsif ($^O eq 'MSWin32' and eval { require Win32::Console }) {
	$o->{readkey} = sub {
	    my $c;
	    # from Term::InKey:
	    eval {
		# Win32::Console's DESTROY does a CloseHandle(), so save it:
		Win32::Console->import;
		$o->{win32_stdin} ||= Win32::Console->new(STD_INPUT_HANDLE());
		my $mode = my $orig = $o->{win32_stdin}->Mode or die $^E;
		$mode &= ~(ENABLE_LINE_INPUT() | ENABLE_ECHO_INPUT());
		$o->{win32_stdin}->Mode($mode) or die $^E;

		$o->{win32_stdin}->Flush or die $^E;
		$c = $o->{win32_stdin}->InputChar(1);
		die $^E unless defined $c;
		$o->{win32_stdin}->Mode($orig) or die $^E;
	    };
	    die "Not implemented on $^O: $@" if $@;
	    $c;
	};
    }
    elsif (eval { require Term::ReadKey }) {
	$o->{readkey} = sub {
	    Term::ReadKey::ReadMode(4, $IN);
	    my $c = getc($IN);
	    Term::ReadKey::ReadMode(0, $IN);
	    $c;
	};
    }
    else {
	$o->{readkey} = sub { scalar <$IN> };
	return $o->{have_readkey} = 0;
    }
    return $o->{have_readkey} = 1;
}
*has_readkey = \&have_readkey;

sub prompt {
    my $o = shift;
    my ($prompt, $default, $completions, $casei) = @_;
    my $term = $o->{term};

    # A closure to read the line.
    my $line;
    my $readline = sub {
	my ($sh, $gh) = @{$term->Features}{qw(setHistory getHistory)};
	my @history = $term->GetHistory if $gh;
	$term->SetHistory() if $sh;
	$line = $o->readline($prompt);
	$line = $default
	    if ((not defined $line or $line =~ /^\s*$/) and defined $default);
	# Restore the history
	$term->SetHistory(@history) if $sh;
	$line;
    };
    # A closure to complete the line.
    my $complete = sub {
	my ($word, $line, $start) = @_;
	return $o->completions($word, $completions, $casei);
    };

    if ($term and $term->ReadLine eq 'Term::ReadLine::Gnu') {
	my $attribs = $term->Attribs;
	local $attribs->{completion_function} = $complete;
	&$readline;
    }
    elsif ($term and $term->ReadLine eq 'Term::ReadLine::Perl') {
	local $readline::rl_completion_function = $complete;
	&$readline;
    }
    else {
	&$readline;
    }
    $line;
}

sub format_pairs {
    my $o    = shift;
    my @keys = @{shift(@_)};
    my @vals = @{shift(@_)};
    my $sep  = shift || ": ";
    my $left = shift || 0;
    my $ind  = shift || "";
    my $len  = shift || 0;
    my $wrap = shift || 0;
    if ($wrap) {
	eval {
	    require Text::Autoformat;
	    Text::Autoformat->import(qw(autoformat));
	};
	if ($@) {
	    warn (
		"Term::Shell::format_pairs(): Text::Autoformat is required " .
		"for wrapping. Wrapping disabled"
	    ) if $^W;
	    $wrap = 0;
	}
    }
    my $cols = shift || $o->termsize->{cols};
    $len < length($_) and $len = length($_) for @keys;
    my @text;
    for my $i (0 .. $#keys) {
	next unless defined $vals[$i];
	my $sz   = ($len - length($keys[$i]));
	my $lpad = $left ? "" : " " x $sz;
	my $rpad = $left ? " " x $sz : "";
	my $l = "$ind$lpad$keys[$i]$rpad$sep";
	my $wrap = $wrap & ($vals[$i] =~ /\s/ and $vals[$i] !~ /^\d/);
	my $form = (
	    $wrap
	    ? autoformat(
		"$vals[$i]", # force stringification
		{ left => length($l)+1, right => $cols, all => 1 },
	    )
	    : "$l$vals[$i]\n"
	);
	substr($form, 0, length($l), $l);
	push @text, $form;
    }
    my $text = join '', @text;
    return wantarray ? ($text, $len) : $text;
}

sub print_pairs {
    my $o = shift;
    my ($text, $len) = $o->format_pairs(@_);
    $o->page($text);
    return $len;
}

# Handle backslash translation; doesn't do anything complicated yet.
sub process_esc {
    my $o = shift;
    my $c = shift;
    my $q = shift;
    my $n;
    return '\\' if $c eq '\\';
    return $q if $c eq $q;
    return "\\$c";
}

# Parse a quoted string
sub parse_quoted {
    my $o = shift;
    my $raw = shift;
    my $quote = shift;
    my $i=1;
    my $string = '';
    my $c;
    while($i <= length($raw) and ($c=substr($raw, $i, 1)) ne $quote) {
	if ($c eq '\\') {
	    $string .= $o->process_esc(substr($raw, $i+1, 1), $quote);
	    $i++;
	}
	else {
	    $string .= substr($raw, $i, 1);
	}
	$i++;
    }
    return ($string, $i);
};

sub line {
    my $o = shift;
    $o->{line}
}
sub line_args {
    my $o = shift;
    my $line = shift || $o->line;
    $o->line_parsed($line);
    $o->{line_args} || '';
}
sub line_parsed {
    my $o = shift;
    my $args = shift || $o->line || return ();
    my @args;

    # Parse an array of arguments. Whitespace separates, unless quoted.
    my $arg = undef;
    $o->{line_args} = undef;
    for(my $i=0; $i<length($args); $i++) {
	my $c = substr($args, $i, 1);
	if ($c =~ /\S/ and @args == 1) {
	    $o->{line_args} ||= substr($args, $i);
	}
	if ($c =~ /['"]/) {
	    my ($str, $n) = $o->parse_quoted(substr($args,$i),$c);
	    $i += $n;
	    $arg = (defined($arg) ? $arg : '') . $str;
	}
# We do not parse outside of strings
#	elsif ($c eq '\\') {
#	    $arg = (defined($arg) ? $arg : '')
#	      . $o->process_esc(substr($args,$i+1,1));
#	    $i++;
#	}
	elsif ($c =~ /\s/) {
	    push @args, $arg if defined $arg;
	    $arg = undef
	}
	else {
	    $arg .= substr($args,$i,1);
	}
    }
    push @args, $arg if defined($arg);
    return @args;
}

sub handler {
    my $o = shift;
    my ($command, $type, $args, $preserve_args) = @_;

    # First try finding the standard handler, then fallback to the
    # catch_$type method. The columns represent "action", "type", and "push",
    # which control whether the name of the command should be pushed onto the
    # args.
    my @tries = (
	[$command, $type, 0],
	[$o->cmd_prefix . $type . $o->cmd_suffix, 'catch', 1],
    );

    # The user can control whether or not to search for "unique" matches,
    # which means calling $o->possible_actions(). We always look for exact
    # matches.
    my @matches = qw(exact_action);
    push @matches, qw(possible_actions) if $o->{API}{match_uniq};

    for my $try (@tries) {
	my ($cmd, $type, $add_cmd_name) = @$try;
	for my $match (@matches) {
	    my @handlers = $o->$match($cmd, $type);
	    next unless @handlers == 1;
	    unshift @$args, $command
		if $add_cmd_name and not $preserve_args;
	    return $o->unalias($handlers[0], $type)
	}
    }
    return undef;
}

sub completions {
    my $o = shift;
    my $action = shift;
    my $compls = shift || [];
    my $casei  = shift;
    $casei = $o->{API}{case_ignore} unless defined $casei;
    $casei = $casei ? '(?i)' : '';
    return grep { $_ =~ /$casei^\Q$action\E/ } @$compls;
}

#=============================================================================
# Term::Shell error messages
#=============================================================================
sub msg_ambiguous_cmd {
    my ($o, $cmd, @c) = @_;
    local $" = "\n\t";
    <<END;
Ambiguous command '$cmd': possible commands:
	@c
END
}

sub msg_unknown_cmd {
    my ($o, $cmd) = @_;
    <<END;
Unknown command '$cmd'; type 'help' for a list of commands.
END
}

#=============================================================================
# Term::Shell private methods
#=============================================================================
sub do_action {
    my $o = shift;
    my $cmd = shift;
    my $args = shift || [];
    my $type = shift || 'run';
    my ($fullname, $cmdname, $handler) = $o->handler($cmd, $type, $args);
    $o->{command}{$type} = {
	cmd	=> $cmd,
	name	=> $cmd,
	found	=> defined $handler ? 1 : 0,
	cmdfull => $fullname,
	cmdreal => $cmdname,
	handler	=> $handler,
    };
    if (defined $handler) {
	# We've found a handler. Set up a value which will call the postcmd()
	# action as the subroutine leaves. Then call the precmd(), then return
	# the result of running the handler.
	$o->precmd(\$handler, \$cmd, $args);
	my $postcmd = CPAN::Term::Shell::OnScopeLeave->new(sub {
	    $o->postcmd(\$handler, \$cmd, $args);
	});
	return $o->$handler(@$args);
    }
}

sub uniq {
    my $o = shift;
    my %seen;
    $seen{$_}++ for @_;
    my @ret;
    for (@_) { push @ret, $_ if $seen{$_}-- == 1 }
    @ret;
}

sub possible_actions {
    my $o = shift;
    my $action = shift;
    my $type = shift;
    my $casei = $o->{API}{case_ignore} ? '(?i)' : '';
    my @keys =	grep { $_ =~ /$casei^\Q$action\E/ }
		grep { exists $o->{handlers}{$_}{$type} }
		keys %{$o->{handlers}};
    return @keys;
}

sub exact_action {
    my $o = shift;
    my $action = shift;
    my $type = shift;
    my $casei = $o->{API}{case_ignore} ? '(?i)' : '';
    my @key =   grep { $action =~ /$casei^\Q$_\E$/ }
		grep { exists $o->{handlers}{$_}{$type} }
		keys %{$o->{handlers}};
    return () unless @key == 1;
    return $key[0];
}

sub is_alias {
    my $o = shift;
    my $action = shift;
    exists $o->{handlers}{$action}{alias} ? 1 : 0;
}

sub has_aliases {
    my $o = shift;
    my $action = shift;
    my @a = $o->get_aliases($action);
    @a ? 1 : 0;
}

sub get_aliases {
    my $o = shift;
    my $action = shift;
    my @a = eval {
	my $hndlr = $o->{handlers}{$action}{alias};
	return () unless $hndlr;
	$o->$hndlr();
    };
    $o->{aliases}{$_} = $action for @a;
    @a;
}

sub unalias {
    my $o = shift;
    my $cmd  = shift;	# i.e 'foozle'
    my $type = shift;	# i.e 'run'
    return () unless $type;
    return ($cmd, $cmd, $o->{handlers}{$cmd}{$type})
	unless exists $o->{aliases}{$cmd};
    my $alias = $o->{aliases}{$cmd};
    # I'm allowing aliases to call handlers which have been removed. This
    # means I can set up an alias of '!' for 'shell', then delete the 'shell'
    # command, so that you can only access it through '!'. That's why I'm
    # checking the {handlers} entry _and_ building a string.
    my $handler = $o->{handlers}{$alias}{$type} || "${type}_${alias}";
    return ($cmd, $alias, $handler);
}

sub find_handlers {
    my $o = shift;
    my $pkg = shift || $o->{API}{class};

    # Find the handlers in the given namespace:
    my %handlers;
    {
	no strict 'refs';
	my @r = keys %{ $pkg . "::" };
	$o->add_handlers(@r);
    }

    # Find handlers in its base classes.
    {
	no strict 'refs';
	my @isa = @{ $pkg . "::ISA" };
	for my $pkg (@isa) {
	    $o->find_handlers($pkg);
	}
    }
}

sub rl_complete {
    my $o = shift;
    my ($word, $line, $start) = @_;

    # If it's a command, complete 'run_':
    if ($start == 0 or substr($line, 0, $start) =~ /^\s*$/) {
	my @compls = $o->complete('', $word, $line, $start);
	return @compls if $o->{command}{comp}{found};
    }

    # If it's a subcommand, send it to any custom completion function for the
    # function:
    else {
	my $command = ($o->line_parsed($line))[0];
	my @compls = $o->complete($command, $word, $line, $start);
	return @compls if $o->{command}{comp}{found};
    }

    ()
}

#=============================================================================
# Two action handlers provided by default: help and exit.
#=============================================================================
sub smry_exit { "exits the program" }
sub help_exit {
    <<'END';
Exits the program.
END
}
sub run_exit {
    my $o = shift;
    $o->stoploop;
}

sub smry_help { "prints this screen, or help on 'command'" }
sub help_help {
    <<'END'
Provides help on commands...
END
}
sub comp_help {
    my ($o, $word, $line, $start) = @_;
    my @words = $o->line_parsed($line);
    return []
      if (@words > 2 or @words == 2 and $start == length($line));
    sort $o->possible_actions($word, 'help');
}
sub run_help {
    my $o = shift;
    my $cmd = shift;
    if ($cmd) {
	my $txt = $o->help($cmd, @_);
	if ($o->{command}{help}{found}) {
	    $o->page($txt)
	}
	else {
	    my @c = sort $o->possible_actions($cmd, 'help');
	    if (@c and $o->{API}{match_uniq}) {
		local $" = "\n\t";
		print <<END;
Ambiguous help topic '$cmd': possible help topics:
	@c
END
	    }
	    else {
		print <<END;
Unknown help topic '$cmd'; type 'help' for a list of help topics.
END
	    }
	}
    }
    else {
	print "Type 'help command' for more detailed help on a command.\n";
	my (%cmds, %docs);
	my %done;
	my %handlers;
	for my $h (keys %{$o->{handlers}}) {
	    next unless length($h);
	    next unless grep{defined$o->{handlers}{$h}{$_}} qw(run smry help);
	    my $dest = exists $o->{handlers}{$h}{run} ? \%cmds : \%docs;
	    my $smry = do { my $x = $o->summary($h); $x ? $x : "undocumented" };
	    my $help = exists $o->{handlers}{$h}{help}
		? (exists $o->{handlers}{$h}{smry}
		    ? ""
		    : " - but help available")
		: " - no help available";
	    $dest->{"    $h"} = "$smry$help";
	}
	my @t;
	push @t, "  Commands:\n" if %cmds;
	push @t, scalar $o->format_pairs(
	    [sort keys %cmds], [map {$cmds{$_}} sort keys %cmds], ' - ', 1
	);
	push @t, "  Extra Help Topics: (not commands)\n" if %docs;
	push @t, scalar $o->format_pairs(
	    [sort keys %docs], [map {$docs{$_}} sort keys %docs], ' - ', 1
	);
	$o->page(join '', @t);
    }
}

sub run_ { }
sub comp_ {
    my ($o, $word, $line, $start) = @_;
    my @comp = grep { length($_) } sort $o->possible_actions($word, 'run');
    return @comp;
}

1;

package CPAN::Term::Shell::OnScopeLeave;

use vars qw($VERSION);

$VERSION = '0.06';

sub new {
    return bless [@_[1 .. $#_]], ref($_[0]) || $_[0];
}

sub DESTROY {
    my $o = shift;
    for my $c (@$o) {
        $c->();
    }

    return;
}

1;

#
# Ext::Shell package
#
package Metabrik::Ext::Shell;
use strict;
use warnings;

use base qw(CPAN::Term::Shell CPAN::Class::Gomor::Hash);

our @AS = qw(
   path_home
   path_cwd
   prompt
   title
   echo
   debug
   _aliases
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Cwd;
use Data::Dumper;
use File::HomeDir qw(home);
use IO::All;
use CPAN::Module::Reload;
use IPC::Run;

use Metabrik;
use Metabrik::Brik::File::Find;

# Exists because we cannot give an argument to Term::Shell::new()
# Or I didn't found how to do it.
our $CTX = {};
our $AUTOLOAD;

sub AUTOLOAD {
   my $self = shift;
   my (@args) = @_;

   if ($AUTOLOAD !~ /^Metabrik::Ext::Shell::run_/) {
      return 1;
   }

   (my $alias = $AUTOLOAD) =~ s/^Metabrik::Ext::Shell:://;

   if ($self->debug) {
      $self->log->debug("autoload[$AUTOLOAD]");
      $self->log->debug("alias[$alias]");
      $self->log->debug("args[@args]");
   }

   my $aliases = $self->_aliases;
   if (exists($aliases->{$alias})) {
      my $cmd = $aliases->{$alias};
      return $self->cmd(join(' ', $cmd, @args));
   }

   return 1;
}

{
   no warnings;

   # We rewrite the log accessor
   *log = sub {
      return $CTX->log;
   };
}

# Converts Windows path
sub _convert_path {
   my ($path) = @_;

   $path =~ s/\\/\//g;

   return $path;
}

#
# Term::Shell::main stuff
#
sub _update_path_home {
   my $self = shift;

   $self->path_home(_convert_path(home()));

   return 1;
}

sub _update_path_cwd {
   my $self = shift;

   my $cwd = _convert_path(getcwd());
   my $home = $self->path_home;
   $cwd =~ s/^$home/~/;

   $self->path_cwd($cwd);

   return 1;
}

sub _update_prompt {
   my $self = shift;
   my ($prompt) = @_;

   if (defined($prompt)) {
      $self->prompt($prompt);
   }
   else {
      my $cwd = $self->path_cwd;

      my $prompt = "meta $cwd> ";
      if ($^O =~ /win32/i) {
         $prompt =~ s/> /\$ /;
      }
      elsif ($< == 0) {
         $prompt =~ s/> /# /;
      }

      $self->prompt($prompt);
   }

   return 1;
}

sub _off_lookup_variables {
   my $self = shift;
   my ($line) = @_;

   my @words = $self->line_parsed($line);
   my $word = $words[0];

   # We lookup variables only for run and set shell Commands
   if (defined($word) && $word =~ /^(?:run|set)$/) {
      for my $this (@words) {
         if ($this =~ /\$([a-zA-Z0-9_]+)/) {
            my $varname = '$'.$1;
            $self->debug && $self->log->debug("lookup: varname[$varname]");

            my $result = $CTX->lookup($varname) || 'undef';
            #$self->debug && $self->log->debug("lookup: result1[$line]");
            $self->debug && $self->log->debug("lookup: result1[..]");
            $line =~ s/\$${1}/$result/;
            #$self->debug && $self->log->debug("lookup: result2[$line]");
            $self->debug && $self->log->debug("lookup: result2[..]");
         }
      }
   }

   return $line;
}

sub init {
   my $self = shift;

   $|++;

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("signal: INT caught");
      $self->run_exit;
      return 1;
   };

   $self->_update_path_home;
   $self->_update_path_cwd;
   $self->_update_prompt;

   if ($CTX->is_used('shell::rc')) {
      $self->debug && $self->log->debug("init: load rc file");

      my $cmd = $CTX->run('shell::rc', 'load');
      for (@$cmd) {
         $self->cmd($_);
      }
   }

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   if ($CTX->is_used('shell::history')) {
      if ($CTX->get('shell::history', 'shell') eq 'undef') {
         $CTX->set('shell::history', 'shell', $self);
      }
      $CTX->run('shell::history', 'load');
   }

   # They are used when core::context init is performed
   # Should be placed in core::context Brik instead of here
   $self->add_handler('run_core::log');
   $self->add_handler('run_core::context');
   $self->add_handler('run_core::global');

   return $self;
}

sub prompt_str {
   my $self = shift;

   return $self->prompt;
}

sub cmdloop {
   my $self = shift;

   $self->{stop} = 0;
   $self->preloop;

   my @lines = ();
   while (defined(my $line = $self->readline($self->prompt_str))) {
      push @lines, $line;

      if ($line =~ /\\\s*$/) {
         $self->_update_prompt('.. ');
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@lines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("cmdloop: lines[@lines]");

      $self->cmd(join('', @lines));
      @lines = ();
      $self->_update_prompt;

      last if $self->{stop};
   }

   $self->run_exit;

   return $self->postloop;
}

#
# Term::Shell::run stuff
#
sub run_exit {
   my $self = shift;

   if ($CTX->is_used('shell::history')) {
      $CTX->run('shell::history', 'write');
   } 

   return $self->stoploop;
}

sub comp_exit {
   return ();
}

sub run_alias {
   my $self = shift;
   my ($alias, @cmd) = @_;

   my $aliases = $self->_aliases;

   if (! defined($alias)) {
      for my $this (keys %$aliases) {
         (my $alias = $this) =~ s/^run_//;
         $self->log->info(sprintf("%-10s \"%s\"", $alias, $aliases->{$this}));
      }

      return 1;
   }

   $aliases->{"run_$alias"} = join(' ', @cmd);
   $self->_aliases($aliases);

   $self->add_handler("run_$alias");

   return 1;
}

sub comp_alias {
   return ();
}

# For shell commands that do not need a terminal
sub run_shell {
   my $self = shift;
   my (@args) = @_;

   if (@args == 0) {
      return $self->log->info("shell <command> [ <arg1:arg2:..:argN> ]");
   }

   my $out = '';
   eval {
      IPC::Run::run(\@args, \undef, \$out);
   };
   if ($@) {
      return $self->log->error("run_shell: $@");
   }

   $CTX->call(sub {
      my %args = @_;

      return my $SHELL = $args{out};
   }, out => $out);

   print $out;

   return 1;
}

sub comp_shell {
   my $self = shift;

   # XXX: use $ENV{PATH} to gather binaries

   return ();
}

# For external commands that need a terminal (vi, for instance)
sub run_system {
   my $self = shift;
   my (@args) = @_;

   if (@args == 0) {
      return $self->log->info("system <command> [ <arg1:arg2:..:argN> ]");
   }

   return system(@args);
}

sub comp_system {
   my $self = shift;

   return $self->comp_shell(@_);
}

sub run_history {
   my $self = shift;
   my ($c) = @_;

   if (! $CTX->is_used('shell::history')) {
      return 1;
   }

   # We want to exec some history command(s)
   if (defined($c)) {
      my $history = [];
      if ($c =~ /^\d+$/) {
         $history = $CTX->run('shell::history', 'get_one', $c);
         $self->cmd($history);
      }
      elsif ($c =~ /^\d+\.\.\d+$/) {
         $history = $CTX->run('shell::history', 'get_range', $c);
         for (@$history) {
            $self->cmd($_);
         }
      }
   }
   # We just want to display history
   else {
      my $history = $CTX->run('shell::history', 'get');
      my $count = 0;
      for (@$history) {
         $self->log->info("[".$count++."] $_");
      }
   }

   return 1;
}

sub comp_history {
   return ();
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   if (defined($dir)) {
      if ($dir =~ /^~$/) {
         $dir = $self->path_home;
      }
      if (! -d $dir) {
         return $self->log->error("cd: $dir: can't cd to this");
      }
      chdir($dir);
      $self->_update_path_cwd;
   }
   else {
      chdir($self->path_home);
      $self->_update_path_cwd;
   }

   $self->_update_prompt;

   return 1;
}

# off: use catch_comp()
#sub comp_cd {
#}

sub run_pl {
   my $self = shift;

   my $line = $self->line;
   $line =~ s/^pl\s+//;

   $self->debug && $self->log->debug("run_pl: code[$line]");

   my $r = $CTX->do($line, $self->echo);
   if (! defined($r)) {
      # When ext::shell:echo is off, we can get undef and it is not an error.
      # XXX: we should use $@ to know if there is an error
      #$self->log->error("pl: unable to execute Code [$line]");
      return;
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

# off: use catch_comp()
#sub comp_pl {
#}

sub run_su {
   my $self = shift;
   my ($cmd, @args) = @_;

   # sudo not supported on Windows 
   if ($^O !~ /win32/i) {
      if (defined($cmd)) {
         system('sudo', $cmd, @args);
      }
      else {
         system('sudo', $0);
      }
   }

   return 1;
}

sub comp_su {
   return ();
}

sub run_reuse {
   my $self = shift;

   my $reused = CPAN::Module::Reload->check;
   if ($reused) {
      $self->log->info("reuse: some modules were reused");
   }

   return 1;
}

sub comp_reuse {
   return ();
}

sub run_use {
   my $self = shift;
   my ($brik, @args) = @_;

   if (! defined($brik)) {
      return $self->log->info("use <brik>");
   }

   my $r;
   # If Brik starts with a minuscule, we want to use Brik in Metabrik sens.
   # Otherwise, it is a use command in the Perl sens.
   if ($brik =~ /^[a-z]/ && $brik =~ /::/) {
      $r = $CTX->use($brik) or return;
      if ($r) {
         $self->log->verbose("use: Brik [$brik] used");
      }

      $self->add_handler("run_$brik");
   }
   else {
      return $self->run_pl($brik, @args);
   }

   return $r;
}

sub comp_use {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find available briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my $available = $CTX->available;
      if ($self->debug && ! defined($available)) {
         $self->log->debug("\ncomp_use: can't fetch available Briks");
         return ();
      }

      # Do not keep already used briks
      my $used = $CTX->used;
      for my $a (keys %$available) {
         next if $used->{$a};
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_show {
   my $self = shift;

   my $status = $CTX->status;

   $self->log->info("Available briks:");

   my $total = 0;
   my $count = 0;
   $self->log->info("   Used:");
   for my $used (@{$status->{used}}) {
      $self->log->info("      $used");
      $count++;
      $total++;
   }
   $self->log->info("   Count: $count");

   $count = 0;
   $self->log->info("   Not used:");
   for my $not_used (@{$status->{not_used}}) {
      $self->log->info("      $not_used");
      $count++;
      $total++;
   }
   $self->log->info("   Count: $count");

   $self->log->info("Total: $total");

   return 1;
}

sub comp_show {
   return ();
}

sub run_help {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->SUPER::run_help;
   }
   else {
      if ($CTX->is_used($brik)) {
         my $attributes = $CTX->used->{$brik}->attributes;
         my $commands = $CTX->used->{$brik}->commands;

         for my $attribute (@$attributes) {
            my $help = $CTX->used->{$brik}->help_set($attribute);
            $self->log->info($help) if defined($help);
         }

         for my $command (@$commands) {
            my $help = $CTX->used->{$brik}->help_run($command);
            $self->log->info($help) if defined($help);
         }
      }
      else {
         # We return to standard help() method
         return $self->SUPER::run_help($brik);
      }
   }

   return 1;
}

sub comp_help {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find help for used briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %{$self->{handlers}}) {
         next unless length($a);
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_set {
   my $self = shift;
   my ($brik, $attribute, $value) = @_;

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info("set <brik> <attribute> <value>");
   }

   my $r = $CTX->set($brik, $attribute, $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute [$attribute] for Brik [$brik]");
   }

   return $r;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   # Completion is for used Briks only
   my $used = $CTX->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_set: can't fetch used Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Attributes
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $attributes = $used->{$brik}->attributes;
      push @comp, @$attributes;
   }
   # We want to complete entered Attribute
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $attributes = $used->{$brik}->attributes;

      for my $a (@$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   elsif ($count == 3 || $count == 4 && length($word) > 0) {
      # Default completion method, we strip first three words "set <brik> <attribute>"
      shift @words;
      shift @words;
      shift @words;
      return $self->catch_comp($word, join(' ', @words), $start);
   }

   return @comp;
}

sub run_get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   # get is called without args, we display everything
   if (! defined($brik)) {
      my $used = $CTX->used or return;

      for my $brik (sort { $a cmp $b } keys %$used) {
         my $attributes = $used->{$brik}->attributes or next;
         for my $attribute (sort { $a cmp $b } @$attributes) {
            $self->log->info("$brik $attribute ".$CTX->get($brik, $attribute));
         }
      }
   }
   # get is called with only a Brik as an arg, we show its Attributes
   elsif (defined($brik) && ! defined($attribute)) {
      my $used = $CTX->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      my %printed = ();
      my $attributes = $used->{$brik}->attributes;
      for my $attribute (sort { $a cmp $b } @$attributes) {
         my $print = "$brik $attribute ".$CTX->get($brik, $attribute);
         $self->log->info($print) if ! exists($printed{$print});
         $printed{$print}++;
      }
   }
   # get is called with is a Brik and an Attribute
   elsif (defined($brik) && defined($attribute)) {
      my $used = $CTX->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      my $attributes = $used->{$brik}->attributes or return;

      if (! $used->{$brik}->can($attribute)) {
         return $self->log->error("get: Attribute [$attribute] does not exist for Brik [$brik]");
      }

      $self->log->info("$brik $attribute ".$CTX->get($brik, $attribute));
   }

   return 1;
}

sub comp_get {
   my $self = shift;

   return $self->comp_set(@_);
}

sub run_run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->info("run <brik> <command> [ <arg1> <arg2> .. <argN> ]");
   }

   my $r = $CTX->run($brik, $command, @args);
   if (! defined($r)) {
      return $self->log->error("run: unable to execute Command [$command] for Brik [$brik]");
   }

   if ($self->echo) {
      print "$r\n";
   }

   return $r;
}

sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   # Completion is for used Briks only
   my $used = $CTX->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_run: can't fetch used Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   if ($self->debug) {
      $self->log->debug("comp_run: word[$word] line[$line] start[$start] count[$count] last[$last]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Commands
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $commands = $used->{$brik}->commands;
      my $attributes = $used->{$brik}->attributes;
      push @comp, @$commands;
      push @comp, @$attributes;
   }
   # We want to complete entered Command and Attributes
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $commands = $used->{$brik}->commands;
      my $attributes = $used->{$brik}->attributes;

      for my $a (@$commands, @$attributes) {
         if ($a =~ /^$word/) {
            push @comp, $a;
         }
      }
   }
   # Else, default completion method on remaining word
   elsif ($count == 3 || $count == 4 && length($word) > 0) {
      # Default completion method, we strip first three words "run <brik> <command>"
      shift @words;
      shift @words;
      shift @words;
      my $line = join(' ', @words);
      #$self->log->verbose("word[$word] line[$line] start[$start] last[$last]");
      #my @new = $self->line_parsed($line);
      #$self->log->verbose("new[@new]");
      #return $self->catch_comp($word, $start, $line); #$line, $start);
      return $self->catch_comp($word, $line, $start);
   }

   return @comp;
}

sub run_title {
   my $self = shift;
   my ($title) = @_;

   if (! defined($title)) {
      return $self->log->info("title <title>");
   }

   print "\c[];$title\a\e[0m";

   return $self->title($title);
}

sub comp_title {
   return ();
}

sub run_script {
   my $self = shift;
   my ($script) = @_;

   if (! defined($script)) {
      return $self->log->info("script <file>");
   }

   if (! -f $script) {
      return $self->log->error("script: file [$script] not found");
   }

   if ($CTX->is_used('shell::script')) {
      $CTX->set('shell::script', 'file', $script);
      my $lines = $CTX->run('shell::script', 'load');
      for (@$lines) {
         $self->run_exit if /^exit$/;
         $self->cmd($_);
      }
   }
   else {
      return $self->log->info("script: shell::script Brik not used");
   }

   return 1;
}

# off: use catch_comp()
#sub comp_script {
#}

#
# Term::Shell::catch stuff
#
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   # Default to execute Perl commands
   return $self->run_pl(@args);
}

# Default to check for global completion value
sub catch_comp {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   # Be default, we will read the current directory
   if (! length($start)) {
      $start = '.';
   }

   $self->debug && $self->log->debug("catch_comp: word[$word] line[$line] start[$start] count[$count]");

   my @comp = ();

   # We don't use $start here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $CTX->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         $self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      my $home = $self->path_home;
      $start =~ s/^~/$home/;

      if ($start =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }

      $self->debug && $self->log->debug("path[$path]");

      my $find = Metabrik::Brik::File::Find->new or return $self->log->error("file::fine: new");
      $find->init;
      $find->path($path);
      $find->recursive(0);

      my $found = $find->all('.*', '.*');

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

1;

__END__
