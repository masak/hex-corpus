use HexDB;
use Test;

{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 1);

    my @matches = $db.moves.grep(matcher {;});

    is +@matches, 1, "one move found, because we're matching on everything";
}

#    . . b .
#     . . . A      A = <3, 5>
#      . C . .     C = <4, 3>
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 5);
    $db.addMove($game, 2, 4);
    $db.addMove($game, 4, 3);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
    });

    is +@matches, 1, "there are three moves, but only C matches the criterion";
}

#    . . b .
#     . . ? A      A = <3, 5>
#      . C . .     C = <4, 3>
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 5);
    $db.addMove($game, 2, 4);
    $db.addMove($game, 4, 3);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], friendly;
    });

    is +@matches, 0, "this search matches no moves";
}

#    . . b .
#     . . . A      A = <3, 5>
#      . C . .     C = <4, 3>
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 5);
    $db.addMove($game, 2, 4);
    $db.addMove($game, 4, 3);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
    });

    is +@matches, 1, "this one, however, does match; asserting an empty cell";
}

#    . d b .       b = <0, 2>  d = <0, 1>
#     . . . A
#      . C . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 1, 3);
    $db.addMove($game, 0, 2);
    $db.addMove($game, 2, 1);
    $db.addMove($game, 0, 1);

    my @matches = $db.moves.grep(matcher {
        at [1, 0], friendly;
    });

    is +@matches, 1, "a friendly cell can be black";
}

#    . . C .       C = <2, 4>
#     . . . b
#      . A . .     C = <4, 3>
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 4, 3);
    $db.addMove($game, 3, 5);
    $db.addMove($game, 2, 4);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    });

    is +@matches, 1, "the pattern matches even when rotated";
}

#    . . . .
#     . . A .      A = <1, 2>
#      . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 1, 2);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    });

    is +@matches, 1, "a stone can match past an edge";
}

#    . . A .
#     . b . .      b = <1, 1>
#      . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 0, 2);
    $db.addMove($game, 1, 1);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    });

    is +@matches, 1, "stones match only their own edge";
}

#    . . A .    (swapped out)
#     . . . C
#      b d . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 2);
    $db.addMove($game, Swap);   # so there's now a Black stone at (2, 3)
    $db.addMove($game, 4, 3);

    my @bridges = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    });

    is +@bridges, 0, "no bridge because that stone was swapped away";
}

{
    my $matcher = matcher {
        at [1, 1], friendly;
    };
    ok $matcher.symmetric, "matcher is mirror-symmetric";
}

{
    my $matcher = matcher {
        at [1, 1], friendly;
        at [2, 0], friendly;
    };
    ok !$matcher.symmetric, "matcher is not mirror-symmetric";
}

{
    my $matcher = matcher {
        at [0, 1], friendly;
        at [1, -1], friendly;
    };
    ok $matcher.symmetric, "matcher is mirror-symmetric, but along a different line";
}

{
    my $matcher = matcher {
        at [1, 0], friendly;
        at [-1, 1], friendly;
    };
    ok $matcher.symmetric, "a third symmetry line";
}

{
    my $matcher = matcher {
        at [-1, 2], friendly;
        at [-1, 0], friendly;
    };
    ok $matcher.symmetric, "a fourth symmetry line";
}

{
    my $matcher = matcher {
        at [-1, 1], friendly;
        at [0, 1], friendly;
    };
    ok $matcher.symmetric, "a fifth symmetry line";
}

{
    my $matcher = matcher {
        at [-1, 2], friendly;
        at [-1, -1], friendly;
    };
    ok $matcher.symmetric, "a sixth symmetry line";
}

#    . . b .       b = <2, 4>
#     . . . A      A = <3, 5>
#      . C . .     C = <4, 3>
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 5);
    $db.addMove($game, 2, 4);
    $db.addMove($game, 4, 3);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [-1, 2], hostile;
    });

    is +@matches, 1, "knows how to match hostile pieces";
}

#    . . b .       b = <2, 4>
#     . . . A      A = <3, 5>
#      . C . .     C = <4, 3>
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 3, 5);
    $db.addMove($game, 2, 4);
    $db.addMove($game, 4, 3);

    my @matches = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [2, -1], hostile;
    });

    is +@matches, 1, "can match against mirror images";
}

#    . . . .
#     . . A .
#      . b . .
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 1, 2);
    $db.addMove($game, Swap);

    my @bridges = $db.moves.grep(matcher {
        at [1, 1], friendly;
        at [1, 0], empty;
        at [0, 1], empty;
    });

    is +@bridges, 2, "swap moves can match as placements";
}


done;
