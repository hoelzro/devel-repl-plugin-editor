## no critic (RequireUseStrict)
package Devel::REPL::Plugin::Editor;

## use critic (RequireUseStrict)
use Devel::REPL::Plugin;
use File::Slurp qw(read_file);
use File::Temp ();

use namespace::clean -except => 'meta';

sub BEFORE_PLUGIN {
    my ( $repl ) = @_;

    $repl->load_plugin('Turtles');
    $repl->meta->add_method(command_edit => sub {
        my ( $self, undef, $filename ) = @_;

        my $tempfile;

        # If filename was not provided, make one up
        if(!defined($filename) || $filename eq '') {
            $tempfile = File::Temp->new(SUFFIX => '.pl');
            close $tempfile;
            $filename = $tempfile->filename;
        }

        system $ENV{'EDITOR'}, $filename;

        my $code = read_file($filename);
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

=begin comment

=over

=item BEFORE_PLUGIN

=back

=end comment

=cut
