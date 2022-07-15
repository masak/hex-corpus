Take this position as an example:

    . . . . . . .
     . a a a . .
    . ; . . ; . .
     b . . . c .
    b . b ; . c .
     b b ; c c .

It consists of three **chains**, which for the purposes of this text is our
smallest unit of concern. The only requirement on a chain is that its cells
are *directly* connected. There can be no gaps in a chain, not even gaps that
can obviuosly be filled in.

There are four inter-chain **links** in the picture, marked as semicolons.
These links are all simple; a link can also be complex and encompass multiple
cells:

    d , .
     , ; .
    . , ,
     . e .

Here the semicolon marks the main cell of the link. The commas mark cells that
need to be empty.

Two different links may overlap. If they do, it may or may not be possible to
use them both at the same time.

Our goal is to arrive at a good picture of the **groups**; the sets of chains
that are strongly connected to each other. In the case of the `a`, `b`, `c`
chains above, the links are as follows, in textual order:

    l1: a ~ b
    l2: a ~ c
    l3: b ~ c
    l4: b ~ c

Because `l3` and `l4` connect the same two chains, we can consider those two
chains to be a **strongly connected**, and we are thus able to treat them as a
group; let us call it `bc`. We can replace mentions of the individual chains
`b`, `c` with this group. And the links `l3` and `l4` are used and cannot be
used again. The table of links thus looks like this:

    l1: a ~ bc
    l2: a ~ bc

Which reveals a *new* strong connection, and we can form `abc`, showing in this
case that all three chains make up a single group.

This process ends somewhere, with us unable to form bigger groups. Those groups
which still have unused links between them are said to be **weakly connected**.
Weak connectedness is an equivalence relation, but it doesn't allow the
formation of bigger groups. `d` and `e` are weakly connected &mdash; and if
the semicolon were filled with a friendly piece, that piece would form a new
chain `f`, and the new links between all the chains would allow us to form the
group `def`. (In fact, "putting a piece here would form a strong connection"
is a good formalization of the intuitive notion of "link".)

Now, here is the thing:

* In some cases, the above algorithm might find a pair of links and use them to
  make a bigger group, while at the same time in the table of links there was
  another pair that it might equally well have chosen. In a sense, the
  algorithm "decides" to go with one pair of links instead of the other.

* Such an arbitrary choice may not matter in the end; for example, it may just
  mean groups get formed in a different order, but eventually the same biggest
  possible group gets formed, consisting of exactly the same chains no matter
  which link pair choices were made.

* Or, quite possibly, it *may* matter, and we end up with two *different*
  biggest possible groups. This seems especially likely to me for complex
  links, which are more likely to overlap with each other.

Let us call a board position where two different biggest possible groups can be
formed an **ambiguous group position**.

Question: are there any ambiguous group positions in the corpus?

**Update**: Yes. A script I wrote found the following position in
`hvh/1401972`:

     # # # c .
    # e e . .
     # . . f .

Where we clearly have either `cf` or `ef` but not both.

This answer, obvious in retrospect as it is, leads on to further
investigations and questions.

* First, currently the script finds the position but flags it for the wrong
  reasons. See [the commit where this was
  explained](https://github.com/masak/hex-corpus/commit/e9301871e755f63554e195d7060bb49a6cb6949f).
  Need to look into that.

* Second, though this *is* an ambiguous position, it's not a very interesting
  one. Why? Because the `e` chain is all but surrounded by the opponent, and
  doesn't confer any strategic advantage. The `c` chain could turn out useful,
  though. The choice between the two groupings is easy in this case. So
  what we're *really* looking for is *interesting* ambiguous group positions,
  ones where the choice isn't trivial. In order to do that, we also need a way
  to mark chains/groups as useful or useless.

Some progress. I like how getting some of the answers immediately leads to more
precise questions.

**Another update, much later**: Here's my current thinking.

* **Links** are real and unquestionable. They exist between chains of the
  same color. A link always has a physical extent on the board, taking up 1,
  3, or 5 empty cells between two chains. A move can act to create friendly
  links and/or destroy enemy links.

* Between two given chains there may be zero or more links.

* **Using** a link means laying claim to the underlying cells spanned by that
  link. The one restriction is that no two links of the same color may use
  any cell more than once. Using two overlapping links at the same time is
  disallowed.

* Using two or more links between two given chains causes those two chains
  to **meld** together. Melding is an equivalence relation; in particular, it
  is transitive: melding `a` with `b` and `b` with `c` (in any order) causes
  `a` to have melded with `c`.

* A **cluster** is a complete set of choices whether to use each of a set of
  links. A cluster is **maximal** if no link uses can be added to cause another
  meld. A cluster is **frugal** if no link use can be removed without undoing
  a meld.

* The task is to find (for each player) all the maximal clusters. There is
  always at least one; whenever there are overlapping links there might be
  several. Focusing on the frugal maximal clusters also cuts down the choice
  a little without losing information. Each such cluster represents a
  significant choice of one link over another somewhere.

* Maximal clusters aren't necessarily "bigger is better" &mdash; they have
  to be evaluated in context. The cluster that gives the most advantage on
  the board is the best one.

* A game position is ambiguous if either player has more than one cluster.
  This may or may not matter if one cluster stands out as the obviously best
  one. On the other hand, ambiguity can also be played to the player's
  advantage by keeping two future options open at the same time.

* A **group** is defined only inside a given cluster as an equivalence class
  of melded chains. Groups can still have links between them, but never
  enough to meld.
