#### Arrays
ArrayMonad = {
    bind : (m, f) ->
        mapped = m.map f
        return Array::concat.apply [], mapped
    return : (a) -> [a]
    zero : []
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

test "Array Guard", ->
    m = mdo ArrayMonad
        (x) <- [1..3]
        (y) <- ['a', 'b']
        mzero when x is 2 and y is 'b'
#         ArrayMonad.guard (x isnt 2 or y isnt 'b')
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

# when
test "when", ->
    results = []
    m = mdo ArrayMonad
        (x) <- [1..4]
        ArrayMonad.return results.push x when x >= 3
        [x]
    arrayEq [1..4], m
    arrayEq [3, 4], results

# this binding
ArrayMonadHelper = class ArrayMonadHelper
    constructor: ->
        @fudge = 3

    munge: (a) -> a + @fudge

    test: ->
        m = mdo ArrayMonad
            (x) <- [1..3]
            (y) <- [this.munge x]
            mreturn y
        arrayEq [4, 5, 6], m

helper = new ArrayMonadHelper
helper.test()

#### Continuations
cpsreturn = (args...) -> (f) -> f args...
CPSHelper = class CPSHelper
    constructor: ->
        @results = []

    addResult: (x) ->
        cpsreturn @results.push x

    getSomeData: (data, err=false) ->
        (f) -> f err, "Data is #{data}"


test "simple cps", ->
    cpshelper = new CPSHelper
    ( ->
        c = cpsdo
            (err, data) <- this.getSomeData "data1"
            this.addResult data when not err
            (err, data) <- this.getSomeData "data2", true
            this.addResult data when not err
            (err, data) <- this.getSomeData "data3"
            when not err
                this.addResult data
            cpsreturn null
    ).call cpshelper
    arrayEq ["Data is data1", "Data is data3"], cpshelper.results

test "guard in cps", ->
    cpshelper = new CPSHelper
    ( ->
        c = cpsdo
            (err, data) <- this.getSomeData "data1"
            this.addResult data when not err
            mzero when err
            (err, data) <- this.getSomeData "data2", true
            mzero when err
            this.a data when not err
            (err, data) <- this.getSomeData "data3"
            mzero when err
            this.addResult data
            mreturn null
    ).call cpshelper
    arrayEq ["Data is data1"], cpshelper.results

test "mlet in cps", ->
    cpshelper = new CPSHelper
    ( ->
        c = cpsdo
            mlet [err, data] <- [false, "data1"]
            this.addResult data when not err
            mlet [err, data] <- [true, "data2"]
            this.addResult data when not err
            mlet [err, data] <- [false, "data3"]
            when not err
                this.addResult data
            cpsreturn null
    ).call cpshelper
    arrayEq ["data1", "data3"], cpshelper.results

test "mreturn in cps", ->
    cpshelper = new CPSHelper
    ( ->
        c = cpsdo
            (err, data) <- mreturn false, "data1"
            this.addResult data when not err
            ([err, data]) <- mreturn [true, "data2"]
            this.addResult data when not err
            ([err, data]) <- mreturn [false, "data3"]
            when not err
                this.addResult data
            cpsreturn null
    ).call cpshelper
    arrayEq ["data1", "data3"], cpshelper.results

