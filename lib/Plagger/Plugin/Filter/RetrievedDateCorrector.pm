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
    if ( $self->is_new( $entry ) ) {
        $date = Plagger::Date->now();
        # record that we saw this entry when it was new
        $context->log(debug => "RetrievedDateCorrector seen a new one!");
        $db->create_entry( $id , $date->epoch );
    } else {
        # replace the date of the entry with the retrieved value
        $context->log(debug => "RetrievedDateCorrector cache HIT!");

        $date = Plagger::Date->from_epoch( $db->find_entry( $id ) );
    }
    # in all cases the date is replaced 
    $entry->date( $date );
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::RetrievedDateCorrector - Ignore the date of the article 

=head1 SYNOPSIS

  - module: Filter::RetrievedDateCorrector
    config:
      path: ./Retrieved.db

=head1 DESCRIPTION

This plugin filters entries and replaces the current date with the retrieved date.
The retrieved date is also cached. 

This plugin is meant to fix glaring failures in how the planet module orders articles.

=head1 CONFIG

=over 4

=item path

Sets the file to record where we saw it.

=back

=head1 AUTHOR

Abram Hindle

=head1 SEE ALSO

L<Plagger>, L<Plagger::Rule::Deduped::DB_File>

=cut
