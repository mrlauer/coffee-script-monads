#### Arrays
bindArray = (m, f) ->
    mapped = m.map f
    return Array::concat.apply [], mapped

ifArray = (cond) ->
    if cond
        [null]
    else
        []

test "Array Monad Simple", ->
    l = [1..3]
    m = mdo bindArray
        (a) <- l
        [1..a]
    arrayEq [1, 1, 2, 1, 2, 3], m

test "Array Monad More Complex", ->
    m = mdo bindArray
        (l) <- [1..3]
        (ll) <- ['a', 'b']
        mlet (sum) <- l + ll
        [sum]
    arrayEq ['1a', '1b', '2a', '2b', '3a', '3b'], m

test "Array If", ->
    m = mdo bindArray
        (x) <- [1..3]
        (y) <- ['a', 'b']
        ifArray (x isnt 2 or y isnt 'b')
        [x + y]
    arrayEq ['1a', '1b', '2a', '3a', '3b'], m

test "Let", ->
    y=1
    m = mdo bindArray
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
        m = mdo bindArray
            (x) <- [1..3]
            (y) <- [this.munge x]
            [y]
        arrayEq [4, 5, 6], m

helper = new ArrayMonadHelper
helper.test()

#### Continuations
results = []

