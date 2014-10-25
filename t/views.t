use HexDB;
use Test;

#    . . . B
#     . . . .
#      . . D .
#       A . . C
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 0);   # A
    $db.addMove($game, 12, 12);
    $db.addMove($game, 0, 3);   # B
    $db.addMove($game, 12, 11);
    $db.addMove($game, 3, 3);   # C
    $db.addMove($game, 12, 10);
    $db.addMove($game, 2, 2);

    my $BRIDGE = matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    };

    my @matches = $db.moves.grep($BRIDGE);
    my @views = views(@matches, $BRIDGE);

    is +@views, 3, "although there is only one matching move, it matches in three ways";
}

done;
