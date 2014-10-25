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

#    . . . B
#     . . y z
#      . . D x
#       A . . C
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 0);   # A
    $db.addMove($game, 2, 3);   # x
    $db.addMove($game, 0, 3);   # B
    $db.addMove($game, 1, 2);   # y
    $db.addMove($game, 3, 3);   # C
    $db.addMove($game, 1, 3);   # z
    $db.addMove($game, 2, 2);

    my $SPECIAL = matcher {
        at [1, 1], friendly;
        at [1, -1], hostile;
    };

    my @matches = $db.moves.grep($SPECIAL);
    my @views = views(@matches, $SPECIAL);

    ok !$SPECIAL.symmetric, "this matcher is not symmetric";
    is +@views, 4, "thanks to reflecting the matcher through an axis, we get 4 views, not 2";
}

#    . . . .
#     . . A .
#      . . . .
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 1, 2);

    my $BRIDGE = matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    };

    my @matches = $db.moves.grep($BRIDGE);
    my @views = views(@matches, $BRIDGE);

    is +@views.grep(*.edgy), 1, "this view matches against an edge";
}

#    . . . .
#     . . . . o .
#      . . A . . o
#       . . . B . .
#          o . . o
#           . o .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 2);
    $db.addMove($game, 12, 12);
    $db.addMove($game, 3, 3);

    my $BRIDGE = matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    };

    my @matches = $db.moves.grep($BRIDGE);
    my @views = views(@matches, $BRIDGE);

    is +@views.grep(*.edgy), 0, "this view doesn't match against an edge";
}

done;
