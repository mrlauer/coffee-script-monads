bindArray = (m, f) ->
    mapped = m.map f
    return Array::concat.apply [], mapped

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
        mlet sum = l + ll
        [sum]
    arrayEq ['1a', '1b', '2a', '2b', '3a', '3b'], m
