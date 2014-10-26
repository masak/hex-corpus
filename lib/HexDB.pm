use v6;

class Swap { ... }
class Resignation { ... }
class Timeout { ... }
class Game { ... }

class Move {
    has Int $.n;
    has Game $.game;
    has Str $.color;

    method cell($r, $c) {
        $.game.cell($.n, $r, $c);
    }

    method gist {
        "[move $.n ($.type) in game $.game.filename()]";
    }

    method type {
        $.color.lc ~ " " ~ self.^name.lc;
    }

    method board {
        $.game.board($.n);
    }
}

class Placement is Move {
    has Int $.row;
    has Int $.col;

    method type {
        callsame() ~ " {chr(ord('a') + $.col)}{$.row + 1}";
    }
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
            @!board[$firstmove.col][$firstmove.row] = $.swap-placement;
        }
    }

    method swap-placement {
        my $game = self;
        my $firstmove = @.moves[0];
        my $row = $firstmove.col;
        my $col = $firstmove.row;
        return Placement.new(:n(1), :$game, :$row, :$col, :color<Black>);
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
                    $_ ~~ Placement && .row == $r && .col == $c
                        given @.moves[$n];
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

    method winner {
        my $losing-move = @.moves[*-1];
        return $losing-move.color eq 'White' ?? 'Black' !! 'White';
    }
}

class HexDB {
    has Set $.games;

    method fromCorpus() {
        my $db = self.new;
        for <mvm hvm hvh> -> $level {
            for dir($level) -> $path {
                $db.gameFromCorpus($path);
            }
        }
        return $db;
    }

    method gameFromCorpus(IO::Path $path) {
        my $filename = ~$path;
        my $game = Game.new(:$filename);

        for $path.IO.lines {
            when /^ (White|Black) ' places ' (\w)(\d+) '.' $/ {
                my $col = ord(~$1) - ord('a');
                my $row = +$2 - 1;
                self.addMove($game, $row, $col);
            }
            when "Black swaps." {
                self.addMove($game, Swap);
            }
            when /^ (White|Black) ' resigns.' $/ {
                self.addMove($game, Resignation);
            }
            when /^ (White|Black) ' times out.' $/ {
                self.addMove($game, Timeout);
            }
            die "Unknown input '$_'";
        }

        return $game;
    }

    multi method addMove(Game $game, Move:U $movetype) {
        $!games ∪= $game;
        my $n = +$game.moves;
        my $color = $game.moves %% 2 ?? 'White' !! 'Black';
        $game.addMove($movetype.new(:$n, :$game, :$color));
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

class Matcher {
    has @.criteria;

    method matches($m is copy, $steps) {
        return False
            unless $m ~~ Placement | Swap;
        if $m ~~ Swap {
            $m = $m.game.swap-placement;
        }
        my $friend-color = $m.color;
        my $hostile-color = $friend-color eq 'White' ?? 'Black' !! 'White';
        for @.criteria -> [Int $x, Int $y, PieceState $ps] {
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

    method symmetric {
        my @fs =
            { $^x + $^y, -$y },     # (1, 0)
            { $^y, $^x },           # (1, 1)
            { -$^x, $x + $^y },     # (0, 1)
            { -$^y - $^x, $y },     # (-1, 2)
            { $^x, -$^y - 2 * $x }, # (-1, 1)
            { $^x, -$x - $^y },     # (-2, 1)
        ;

        my %h = @.criteria.map(-> [$x, $y, $ps] { "<$x $y> $ps" => 1 });
        FLIP:
        for @fs -> &f {
            for @.criteria -> [Int $x, Int $y, PieceState $ps] {
                my ($fx, $fy) = f($x, $y);
                next FLIP
                    unless %h{"<$fx $fy> $ps"} :exists;
            }
            return True;
        }
        return False;
    }

    method ACCEPTS(Move $m) {
        for ^6 -> $steps {
            return True
                if self.matches($m, $steps);
        }
        if !$.symmetric {
            my $flip-matcher = Matcher.new(:criteria(
                @.criteria.map(-> [$x, $y, $ps] { [$y, $x, $ps] })
            ));
            for ^6 -> $steps {
                return True
                    if $flip-matcher.matches($m, $steps);
            }
        }
        return False;
    }
}

sub matcher(&criteria) is export {
    my @criteria = do {
        my @*CRITERIA;
        &criteria();
        @*CRITERIA;
    };

    return Matcher.new(:@criteria);
}

sub rotate([$x is copy, $y is copy], $steps) {
    ($x, $y) = $x + $y, -$x
        for ^$steps;
    return $x, $y;
}

sub at([$x, $y], PieceState:D $ps) is export {
    push @*CRITERIA, [$x, $y, $ps];
}

class View {
    has Move $.move;
    has Int $.steps;
    has Bool $.flipped = False;
    has Matcher $.matcher;

    method edgy {
        my $move =
            $.move ~~ Placement ?? $.move !!
            $.move ~~ Swap      ?? $.move.game.swap-placement !!
            die "Don't know how to handle a ", $.move.WHAT;
        for $.matcher.criteria.list -> $c {
            my ($x, $y) = rotate([$c[0], $c[1]], $.steps);
            my ($row, $col) = $move.row - $y, $move.col + $x + $y;
            return True
                if outside($row) || outside($col);
        }
        return False;
    }
}

sub views(@moves, Matcher $matcher) is export {
    gather for @moves -> $move {
        for ^6 -> $steps {
            if $matcher.matches($move, $steps) {
                take View.new(:$move, :$steps, :$matcher);
            }
        }
        if !$matcher.symmetric {
            my $flip-matcher = Matcher.new(:criteria(
                $matcher.criteria.map(-> [$x, $y, $ps] { [$y, $x, $ps] })
            ));
            for ^6 -> $steps {
                if $flip-matcher.matches($move, $steps) {
                    take View.new(:$move, :$steps, :flipped, :$matcher);
                }
            }
        }
    }
}
