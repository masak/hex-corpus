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
