use v6;

class Swap { ... }
class Resignation { ... }
class Timeout { ... }
class Game { ... }

class Move {
    has Int $.n;
    has Game $.game;

    method cell($r, $c) {
        $.game.cell($.n, $r, $c);
    }

    method gist {
        "[move $.n in game $.game.filename()]";
    }

    method board {
        $.game.board($.n);
    }
}

class Placement is Move {
    has Str $.color;
    has Int $.row;
    has Int $.col;
}

class Swap is Move {}
class Resignation is Move {}
class Timeout is Move {}

constant SIZE = 13;

sub inside { $^coord ~~ ^SIZE }
sub outside { !inside $^coord }

class Game {
    has Str $.filename;
    has Move @.moves;
    has @!board = [Any xx SIZE] xx SIZE;
    has $!swapped = False;

    method addMove($move) {
        @.moves.push($move);
        if $move ~~ Placement {
            @!board[$move.row][$move.col] = $move;
        }
        if $move ~~ Swap {
            $!swapped = True;
            my $firstmove = @.moves[0];
            @!board[$firstmove.row][$firstmove.col] = Any;
            my $row = $firstmove.col;
            my $col = $firstmove.row;
            @!board[$row][$col] = Placement.new(:n(1), :game(self), :$row, :$col, :color<Black>);
        }
    }

    method cell($n, $r, $c) {
        return 'White'
            if outside($r) && inside($c);
        return 'Black'
            if inside($r) && outside($c);
        return 'empty'
            if outside($r) && outside($c);

        my $placement = @!board[$r][$c];
        return 'empty'
            unless $placement;
        return 'empty'
            if $n < $placement.n;
        if $n == 0 && $!swapped {
            return $r == .row && $c == .col
                ?? .color
                !! 'empty'
                given @.moves[0];
        }
        return $placement.color;
    }

    method board($n) {
        join "\n", (^SIZE).map: -> $r {
            "  " x $r ~
            join "", (^SIZE).map: -> $c {
                sub currentmove() {
                    .row == $r && .col == $c given @.moves[$n];
                }
                my $cell = self.cell($n, $r, $c);
                my $contents = $cell eq 'White' ?? 'wh' !!
                               $cell eq 'Black' ?? 'bl' !!
                               '..';
                my ($left, $right) = currentmove() ??
                    ('[', ']') !! (' ', ' ');
                "$left$contents$right";
            }
        };
    }
}

class HexDB {
    has Set $.games;

    method fromCorpus {
        my $db = self.new;
        for <mvm hvm hvh> -> $level {
            for dir($level) -> $path {
                my $filename = ~$path;
                my $game = Game.new(:$filename);

                for $path.IO.lines {
                    when /^ (White|Black) ' places ' (\w)(\d+) '.' $/ {
                        my $col = ord(~$1) - ord('a');
                        my $row = +$2 - 1;
                        $db.addMove($game, $row, $col);
                    }
                    when "Black swaps." {
                        $db.addMove($game, Swap);
                    }
                    when /^ (White|Black) ' resigns.' $/ {
                        $db.addMove($game, Resignation);
                    }
                    when /^ (White|Black) ' times out.' $/ {
                        $db.addMove($game, Timeout);
                    }
                    die "Unknown input '$_'";
                }
            }
        }
        return $db;
    }

    multi method addMove(Game $game, Move:U $movetype) {
        $!games ∪= $game;
        my $n = +$game.moves;
        $game.addMove($movetype.new(:$n, :$game));
    }

    multi method addMove(Game $game, Int $row, Int $col) {
        $!games ∪= $game;
        my $n = +$game.moves;
        my $color = $game.moves %% 2 ?? 'White' !! 'Black';
        my $placement = Placement.new(:$n, :$game, :$color, :$row, :$col);
        $game.addMove($placement);
    }

    method moves {
        @.games».moves.flat;
    }
}

enum PieceState <empty friendly hostile>;

sub matcher(&criteria) is export {
    sub match-move($m, $steps, @criteria) {
        my $friend-color = $m.color;
        my $hostile-color = $friend-color eq 'White' ?? 'Black' !! 'White';
        for @criteria -> [Int $x, Int $y, PieceState $ps] {
            my ($rot-x, $rot-y) = rotate([$x, $y], $steps);
            my $r = $m.row - $rot-y;
            my $c = $m.col + $rot-x + $rot-y;
            my $actual = $m.cell($r, $c);
            my $expected = do given $ps {
                when empty { 'empty' }
                when friendly { $friend-color }
                when hostile { $hostile-color }
            };
            return False
                unless $actual eq $expected;
        }

        return True;
    }

    my @criteria = do {
        my @*CRITERIA;
        &criteria();
        @*CRITERIA;
    };

    return Any.new but role {
        method symmetric {
            my @fs =
                { $^x + $^y, -$y },     # (1, 0)
                { $^y, $^x },           # (1, 1)
                { -$^x, $x + $^y },     # (0, 1)
                { -$^y - $^x, $y },     # (-1, 2)
                { $^x, -$^y - 2 * $x }, # (-1, 1)
                { $^x, -$x - $^y },     # (-2, 1)
            ;

            my %h = @criteria.map(-> [$x, $y, $ps] { "<$x $y> $ps" => 1 });
            FLIP:
            for @fs -> &f {
                for @criteria -> [Int $x, Int $y, PieceState $ps] {
                    my ($fx, $fy) = f($x, $y);
                    next FLIP
                        unless %h{"<$fx $fy> $ps"} :exists;
                }
                return True;
            }
            return False;
        }

        method ACCEPTS(Move $m) {
            return False
                unless $m ~~ Placement;
            for ^6 -> $steps {
                return True
                    if match-move($m, $steps, @criteria);
            }
            if !$.symmetric {
                my @flip-criteria = @criteria.map(-> [$x, $y, $ps] { [$y, $x, $ps] });
                for ^6 -> $steps {
                    return True
                        if match-move($m, $steps, @flip-criteria);
                }
            }
            return False;
        }
    };
}

sub rotate([$x is copy, $y is copy], $steps) {
    ($x, $y) = $x + $y, -$x
        for ^$steps;
    return $x, $y;
}

sub at([$x, $y], PieceState:D $ps) is export {
    push @*CRITERIA, [$x, $y, $ps];
}
