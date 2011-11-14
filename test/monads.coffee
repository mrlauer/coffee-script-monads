#### Arrays
ArrayMonad = {
    bind : (m, f) ->
        mapped = m.map f
        return Array::concat.apply [], mapped
    return : (a) -> [a]
    guard : (cond) -> if cond then [null] else []
}

test "Array Monad Simple", ->
    l = [1..3]
    m = mdo ArrayMonad
        (a) <- l
        [1..a]
    arrayEq [1, 1, 2, 1, 2, 3], m

test "Array Monad More Complex", ->
    m = mdo ArrayMonad
        (l) <- [1..3]
        (ll) <- ['a', 'b']
        mlet (sum) <- l + ll
        ArrayMonad.return sum
    arrayEq ['1a', '1b', '2a', '2b', '3a', '3b'], m

test "Array If", ->
    m = mdo ArrayMonad
        (x) <- [1..3]
        (y) <- ['a', 'b']
        ArrayMonad.guard (x isnt 2 or y isnt 'b')
        [x + y]
    arrayEq ['1a', '1b', '2a', '3a', '3b'], m

test "Let", ->
    y=1
    m = mdo ArrayMonad
        (x) <- [1..3]
        mlet (y) <- x+1
        mlet z <- y+1
        [z]

    arrayEq [3..5], m
    # y should not have been touched
    eq y,1
    # kinda messy way to make sure z isn't assigned in the outer scope
    zunassigned = true
    try
        eq z, 0
        zunassigned = false
    catch error
        zunassigned = (error instanceof ReferenceError)
    ok zunassigned

# this binding
ArrayMonadHelper = class ArrayMonadHelper
    constructor: ->
        @fudge = 3

    munge: (a) -> a + @fudge

    test: ->
        m = mdo ArrayMonad
            (x) <- [1..3]
            (y) <- [this.munge x]
            [y]
        arrayEq [4, 5, 6], m

helper = new ArrayMonadHelper
helper.test()

#### Continuations
results = []

