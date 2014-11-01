use HexDB;
use Test;

#    . . . .
#     . . . .
#      . . A .
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 2);   # A

    my $event = $game.moves[0].chainEvent;
    ok $event ~~ CreateChain,
        "placing a piece next to nothing creates a chain";
    my $chain = $event.chain;
    is $chain.color, 'White', "...a white one";
    is +$chain.pieces, 1, "...with one piece in it";
    is $chain.name, 'chAwh', "...with the right name";
}

#    . . . .
#     . . . .
#      . . A B
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 2);   # A
    $db.addMove($game, 12, 12);
    $db.addMove($game, 2, 3);   # B

    my $event = $game.moves[2].chainEvent;
    ok $event ~~ ExtendChain,
        "placing a piece next to a same-colored piece extends the old chain";
    my $chain = $event.chain;
    is $chain.color, 'White', "...it's still white";
    is +$chain.pieces, 2, "...but it now has two pieces";
    is $chain.name, "chAwh'", "...with an apostrophe added to the name";
}

#    . . . .
#     . . . .
#      . . A b
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 2);   # A
    $db.addMove($game, 2, 3);   # b

    my $event = $game.moves[1].chainEvent;
    ok $event ~~ CreateChain,
        "but a piece next to an opposite-colored piece is still a new chain";
    my $chain = $event.chain;
    is $chain.color, 'Black', "...a black one";
    is +$chain.pieces, 1, "...with one piece in it";
    is $chain.name, "chAbl", "...with a suitable name for a black chain";
}

#    . . . .
#     . . . .
#      . A C B
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 1);   # A
    $db.addMove($game, 12, 12);
    $db.addMove($game, 2, 3);   # B
    $db.addMove($game, 12, 11);
    $db.addMove($game, 2, 2);   # C

    my $event = $game.moves[4].chainEvent;
    ok $event ~~ JoinChains,
        "placing a piece between two same-colored chains makes a joined chain";
    my $chain = $event.chain;
    is $chain.color, 'White', "...white";
    is +$chain.pieces, 3, "...now with extra three-piece goodness!";
    is $chain.name, "chABwh", "...with a name combined from the two joined chains";
}

#    . . . .
#     . . . .
#      . . . A  # swapped out
#       . . b .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 2, 3);   # A
    $db.addMove($game, Swap);   # b

    my $event = $game.moves[1].chainEvent;
    ok $event ~~ SwapCreateChain,
        "swapping causes a chain to die and a new one to be created";
    my $chain = $event.chain;
    is $chain.color, 'Black', "...a black one";
    is +$chain.pieces, 1, "...with one piece in it";
    is $chain.name, 'chAbl', "...with the right name";
    is $game.chains<chAwh>.death, 1, "...and the old chain is well and truly dead";
}

#    . . A .
#     . . . .
#      . . . .
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 0, 2);   # A

    my $event = $game.moves[0].chainEvent;
    ok $event ~~ ExtendChain,
        "placing a piece at an edge extends an existing edge chain";
    my $chain = $event.chain;
    is $chain.color, 'White', "...a white one";
    is +$chain.pieces, 2, "...with two pieces in it (edge and new piece)";
    is $chain.name, "chNORTHwh'", "...with an apostrophe added to the edge chain name";
}

#    . . A .
#     . . . .
#      b . . .
#       . . . .
{
    my $db = HexDB.new;
    my $game = Game.new(:filename<testgame>);
    $db.addMove($game, 0, 2);   # A
    $db.addMove($game, Swap);   # b

    my $event = $game.moves[1].chainEvent;
    ok $event ~~ SwapExtendChain,
        "swapping a piece that extended an edge chain, extends another edge chain";
    my $chain = $event.chain;
    is +$chain.pieces, 2, "...with two pieces in it (edge and new piece)";
    is $game.moves[0].chainEvent.chain.death, 1, "the old edge chain died because of the swap";
    ok $game.chains<chNORTHwh''>:exists, "...but a new one was created in its place";
}

done;
