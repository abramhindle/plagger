package Plagger::Plugin::Filter::RetrievedDateCorrector;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Rule::Deduped::DB_File;
use Plagger::Date;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'        => \&initialize,
        'update.entry.fixup' => \&filter,
    );
}

sub initialize {
    my ($self, $context, $args) = @_;
    my $config   = $self->conf;    
    $context->log(debug => "initializing RetrievedDateCorrector");
    # get the path of the db
    my $tmppath = Plagger->context->cache->path_to('Retrieved.db');
    # make the db
    my $db = Plagger::Rule::Deduped::DB_File->new( { 'path' => ($config->{path} || $tmppath) } );
    $self->{replacedate} = $config->{replacedate} || 0;
    $self->{replacefuture} = $config->{replacefuture} || 0;
    $self->{db} = $db;
    $context->log(debug => "initialized RetrievedDateCorrector");

}

#duplicated functionality but I don't trust dedupe
sub id_for {
    my ($self, $entry) = @_;
    if ($entry->date) {
        return join ":", $entry->permalink, $entry->date;
    } else {
        return $entry->permalink;
    }
}
sub is_new {
    my ($self, $entry) = @_;
    return ( $self->{db}->find_entry( $self->id_for($entry) ) )?0:1;
}

sub filter {
    my ($self, $context, $args) = @_;
    my $db = $self->{db};
    my $entry = $args->{entry};
    my $id = $self->id_for($entry);
    my $date = undef;
    my $now = Plagger::Date->now();
    if ( $self->is_new( $entry ) ) {
        $date = $now;
        # record that we saw this entry when it was new
        $context->log(debug => "RetrievedDateCorrector seen a new one!");
        $db->create_entry( $id , $date->epoch );
    } else {
        # replace the date of the entry with the retrieved value
        $context->log(debug => "RetrievedDateCorrector cache HIT!");

        $date = Plagger::Date->from_epoch( $db->find_entry( $id ) );
    }

    if (! $entry->date()) {
        # replace if no date
        $entry->date( $date );
    } elsif ( $self->{replacedate} ) {
        # in all cases the date is replaced 
        $entry->date( $date );
    } elsif ( $self->{replacefuture} && $entry->date > $now) {
        $entry->date( $date );
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::RetrievedDateCorrector - Ignore the date of the article 

=head1 SYNOPSIS

  - module: Filter::RetrievedDateCorrector
    config:
      path: ./Retrieved.db
      replacedate: 1
      replacefuture: 1

=head1 DESCRIPTION

This plugin filters entries and replaces the current date with the
retrieved date.  The retrieved date is also cached in all cases.

There are options where you don't replace the date for every entry,
just the ones missing it. It needs a DB file to operate so it can
remember previous entries from previous runs.

This plugin allows you to order your entries by order of
retrieval. This isn't very useful initially but grows in usefulness
when used in conjunction with the planet module as poorly behaving
feeds are tracked appropraitely for time.

=head1 CONFIG

=over 4

=item path

Sets the file to record where we saw it.

=item replacedate

Should we replace the date of the entry if it has a date?

=item replacefuture

Should we replace the date of the entry if it has a date set in the future?

=back

=head1 AUTHOR

Abram Hindle

=head1 SEE ALSO

L<Plagger>, L<Plagger::Rule::Deduped::DB_File>

=cut
