package Squeeze;
use Modern::Perl;
use Moo;
use namespace::clean;
use Data::Dumper;
use Net::Telnet;
use Types::Standard qw( Str );
use URI::Escape;

has 'host' => ( is      => 'ro',
                isa     => Str,
                default => '192.168.1.101'
              );

has 't' => (
    is  => 'rw',
    isa => sub {

        die "$_[0] is not a Net::Telnet Object!"
          unless ref $_[0] eq 'Net::Telnet';
    },

);

has 'player' => (
    is  => 'rw',
    isa => Str,

                );

sub BUILD
{
    my $self = shift;
    $self->t(
              Net::Telnet->new( Timeout => 10,
                                Port    => 9090,
                                Prompt  => '/[\n]/'
                              ) );
    $self->t->open( $self->host );

}

sub play
{
    my ( $self, $playerId, $track ) = @_;

    $self->runcommand("$playerId play");

}

sub stop
{
    my ( $self, $playerId ) = @_;
    $self->runcommand("$playerId stop");
}

sub playTrack
{
    my ( $self, $playerId, $track ) = @_;
    return 0 unless $track =~ /^\d+$/;
    $self->runcommand("$playerId playlist index $track");
}

sub nextTrack
{
    my ( $self, $playerId ) = @_;
    $self->runcommand("$playerId playlist index +1");
}

sub prevTrack
{
    my ( $self, $playerId ) = @_;
    $self->runcommand("$playerId playlist index -1");
}

sub volUp
{

    my ( $self, $playerId, $change ) = @_;
    return 0 unless $change =~ /^\d+$/;
    $self->runcommand("$playerId  mixer volume +$change");

}

sub volDown
{

    my ( $self, $playerId, $change ) = @_;
    return 0 unless $change =~ /^\d+$/;
    $self->runcommand("$playerId  mixer volume -$change");

}

sub playlistLength
{
    my ( $self, $playerId ) = @_;
    my @a = $self->runcommand("$playerId  playlist tracks ?");
    return $self->pick_field( 3, @a );

}

sub currentTrackNumber
{
    my ( $self, $playerId ) = @_;
    my @a = $self->runcommand("$playerId  playlist index ?");
    return $self->pick_field( 3, @a );

}

sub currentTrack
{
    my ( $self, $playerId ) = @_;
    my @a = $self->runcommand("$playerId  playlist index ?");
    my $currentTrackNumber = $self->pick_field( 3, @a );

    my $album =
      $self->pick_field( 4,
                         $self->runcommand(
                               "$playerId playlist album $currentTrackNumber ?")
                       );
    my $artist =
      $self->pick_field( 4,
                         $self->runcommand(
                              "$playerId playlist artist $currentTrackNumber ?")
                       );
    my $title =
      $self->pick_field( 4,
                         $self->runcommand(
                               "$playerId playlist title $currentTrackNumber ?")
                       );

    return ( $currentTrackNumber, $title, $album, $artist );

}

sub playlist
{
    my ( $self, $playerId ) = @_;

    my $playlistLength     = $self->playlistLength($playerId);
    my $currentTrackNumber = $self->currentTrackNumber($playerId);
    for my $i ( 0 .. $playlistLength - 1 )
    {

        my $album =
          $self->pick_field( 4,
                           $self->runcommand("$playerId playlist album $i ?") );
        my $artist =
          $self->pick_field( 4,
                             $self->runcommand(
                                               "$playerId playlist artist $i ?")
                           );
        my $title =
          $self->pick_field( 4,
                           $self->runcommand("$playerId playlist title $i ?") );

        my $iscurrent = ( $i == $currentTrackNumber ) ? '>' : ' ';
        say sprintf "%s %3d - '%s' from %s by %s", $iscurrent, $i, $title,
          $album,
          $artist;

    }
}

sub playlists
{
    my ($self) = @_;
    my @a = $self->runcommand("playlists 0");

    return uri_unescape( join( ' ', @a ) );

}

sub playPlaylist
{
    my ( $self, $playerId, $playlistId ) = @_;
    return unless defined $playlistId;
    my @a = $self->runcommand(
                  "$playerId playlistcontrol cmd:load playlist_id:$playlistId");
    $self->playTrack( $playerId, 0 );
    return uri_unescape( join( ' ', @a ) );

}

sub shufflePlaylist
{
    my ( $self, $playerId ) = @_;
    my @a = $self->runcommand("$playerId playlist shuffle 1");

    return uri_unescape( join( ' ', @a ) );

}

sub getPlayerIds
{

    my ( $self, $playernum ) = @_;
    my @players;
    my $count = $self->pick_field( 2, $self->runcommand('player count ?') );

    if ($count)
    {
        for ( my $i = 0 ; $i < $count ; $i += 1 )
        {
            my $pn =
              $self->pick_field( 3, $self->runcommand("player name $i ?") );
            my $pid = $self->pick_field( 3, $self->runcommand('player id ?') );
            if ( defined $pn && $pn ne '?' )
            {
                push @players,
                  { name => $pn,
                    pid  => $pid
                  };
            }
            else
            {
                if ( $pid && $pid ne '?' )
                {
                    push @players,
                      { name => $pid,
                        pid  => $pid
                      };
                }
                warn "Player discovery playname issue $i-$pn-$pid";
            }
        }
    }
    if ( defined $playernum )
    {
        say "GOT $playernum == ",$players[$playernum]->{ pid };
        return $players[$playernum]->{ pid };
    }
    return @players;
}

sub randomPlay
{
    my ( $self, $playerId ) = @_;
    my @a = $self->runcommand("$playerId randomplay tracks ");

    return uri_unescape( join( ' ', @a ) );

}

# a5:41:d2:cd:cd:05 playlistcontrol cmd:load album_id:22

sub pick_field
{
    my ( $self, $field, @output ) = @_;
    my $count = 0;
    my $a = uri_unescape( ( split /\s+/, $output[0] )[$field] );
    $a = '' unless defined $a;
    return $a;    #uri_unescape( ( split /\s+/, $output[0] )[$field] );

}




sub runcommand
{
    my ( $self, $command ) = @_;
    my $count = 0;
    my @lines = $self->t->cmd($command);
    return @lines;
}

1;
