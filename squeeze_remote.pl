#!/usr/bin/perl
use Modern::Perl;
use FindBin;    # locate this script
use lib "$FindBin::Bin/lib";
use Squeeze;
use Data::Dumper;

my @order    = qw{e r  n p j l sp pp};
my $s        = Squeeze->new();
my $playerId = 'd0:df:9a:0f:e0:ba';

my $exit = 1;
my %things = (
    'e' => { short   => 'exit',
             command => sub {$exit = 0}
           },
    'n' => { short   => 'next track',
             command => sub {$_[0]->nextTrack( $_[1] )}
           },
    's' => { short   => 'stop',
             command => sub {$_[0]->stop( $_[1] )}
           },
    ,
    'p' => { short   => 'previous track',
             command => sub {$_[0]->prevTrack( $_[1] )}
           },
    ,
    'r' => { short   => 'refresh',
             command => sub { }
           },
    'l' => { short   => 'show playlist',
             command => sub {$_[0]->playlist( $_[1] )}
           },
    'sp' => { short   => 'show playlists',
              command => sub {my $a = $_[0]->playlists( $_[1] ); say $a}
            },
    'pp' => { short   => 'play playlists',
              command => sub {$_[0]->playPlaylist( $_[1], $_[2] )}
            },
    'shp' => { short   => 'shuffle playlists',
               command => sub {say $_[0]->shufflePlaylist( $_[1] )}
             },
    'rp' => { short   => 'replay playlists',
              command => sub {$_[0]->playTrack( $_[1], 0 )}
            },
    'j' => { short   => 'jump to track number in playlist',
             command => sub {$_[0]->playTrack( $_[1], $_[2] )}
           },
    'rp' => {
        short => 'random mix
        ',
        command => sub {$_[0]->randomPlay( $_[1] )}
            },
    'lp' => {
        short   => 'list players',
        command => sub {
            my @a = $_[0]->getPlayerIds();
            say "$_ $a[$_]->{name}" for ( 0 .. $#a );
          }
    },
    'selp' => { short   => 'list players',
                command => sub {$playerId = $_[0]->getPlayerIds( $_[2] );}
              },

             );
while ($exit)
{

    say join ' ', $s->currentTrack($playerId);

    say '-' x 20, "\nCommands\n", '-' x 20;

    for my $key (@order)
    {
        say "$key - $things{$key}{short}";
    }

    my $a = <>;
    my $b;
    chomp $a;
    if ( $a =~ /:/ )
    {
        ( $a, $b ) = split /:/, $a;
    }

    print "\033[2J";
    print "\033[0;0H";    #jump to 0,0
    next unless $things{ $a };
    $things{ $a }{ command }->( $s, $playerId, $b );

}
