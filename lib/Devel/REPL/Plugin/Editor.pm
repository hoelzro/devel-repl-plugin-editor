package Devel::REPL::Plugin::Editor;

use Devel::REPL::Plugin;
use File::Slurp qw(read_file);
use File::Temp ();

use namespace::clean -except => 'meta';

my $repl;
my $tempfile;

sub BEFORE_PLUGIN {
    ( $repl ) = @_;

    $repl->load_plugin('Turtles');
    $repl->meta->add_method(command_edit => sub {
        my ( $self ) = @_;

        my $tempfile = File::Temp->new(SUFFIX => '.pl');
        close $tempfile;

        system $ENV{'EDITOR'}, $tempfile->filename;

        my $code = read_file($tempfile->filename);
        chomp $code;
        my $pristine_code = $code;

        if($self->can('current_package')) {
            $code = "package " . $self->current_package . ";\n$code";
        }

        my $rl = $repl->term;

        if($rl->ReadLine eq 'Term::ReadLine::Gnu') {
            my $location = $rl->where_history;
            $rl->replace_history_entry($location, $pristine_code);
        } else {
            $repl->term->addhistory($pristine_code);
        }

        return $repl->formatted_eval($code);
    });
}

1;

__END__

# ABSTRACT: Add #edit command to drop into an editor for longer expressions

=head1 SYNOPSIS

  # in ~/.re.pl/repl.rc
  $_REPL->load_plugin('Editor');

=head1 DESCRIPTION

This plugin adds an C<edit> command to your REPL, invoked using C<#edit> (or
using whatever L<Devel::REPL::Plugin::Turtles/default_command_prefix> is).
When you run the the edit command, the REPL drops you into C<$ENV{'EDITOR'}>,
and the code you type in that file is executed after you exit the editor.

=head1 SEE ALSO

L<Devel::REPL>

=cut
