package SVN::Simple::Client::Types;

# ABSTRACT: Moose types for Subversion clients

use strict;
use DateTime::Format::ISO8601;
use Devel::Symdump;
use English '-no_match_vars';
use MooseX::Types -declare => [
    qw(
        SvnError SvnUri
        Revision RevisionNumber RevisionEnum RevisionDate
        )
];
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
use MooseX::Types::Moose qw(Int Str);
use MooseX::Types::URI 'Uri';
use Regexp::DefaultFlags;
## no critic (RequireDotMatchAnything, RequireExtendedFormatting, RequireLineBoundaryMatching)
use Readonly;
use SVN::Client;
use SVN::Simple::Client::Constants ':all';
use TryCatch;
use URI;

=for :stopwords SvnError SvnUri RevisionNumber RevisionEnum RevisionDate

=head1 TYPES

=head2 SvnError

=cut

class_type SvnError,
    { class => '_p_svn_error_t' },
    where { $ARG->apr_err() ~~ keys %ERROR_NAME };

=head2 SvnUri

A valid Subversion identifier within a repository, either a file: or
http(s):// URI.

=cut

subtype SvnUri, as Uri, where { $ARG->scheme() =~ /\A (?:file | https?) \z/ },
    message {'Invalid Subversion URI'};
SvnUri->coercion( Uri->coercion );

=head2 Revision and its subtypes

A C<Revision> is a valid Subversion revision identifier, incorporating the
following subtypes:

=cut

subtype Revision, as RevisionNumber | RevisionEnum | RevisionDate, where {
    is_RevisionNumber($ARG) or is_RevisionEnum($ARG) or is_RevisionDate($ARG);
}, message {'Invalid Subversion revision'};

=over

=item RevisionNumber

A positive integer, corresponding to a Subversion repository revision number.

=cut

subtype RevisionNumber, as Int, where { $ARG > 0 };

=item RevisionEnum

A string containing any one of the following values used as symbolic revisions
in Subversion: C<HEAD>, C<BASE>, C<COMMITTED>, C<PREV>, C<WORKING>.

=cut

enum RevisionEnum, qw(HEAD BASE COMMITTED PREV WORKING);

=item RevisionDate

A string containing an ISO8601-formatted date enclosed in curly braces
(C<{> and C<}>).

=cut

subtype RevisionDate, as Str, where {
    /\A { (.+) } \z/ or return 0;
    try { DateTime::Format::ISO8601->parse_datetime($1) } catch { return 0 };
    return 1;
};

=back

=cut

1;

__END__

=head1 DESCRIPTION

This is a L<Moose|Moose> type library useful to Subversion clients.

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use SVN::Simple::Client::Types ':all';

    has url      => (is => 'ro', isa => SvnUri);
    has revision => (is => 'rw', isa => Revision);