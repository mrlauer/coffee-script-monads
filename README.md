Monads in Coffeescript
======================

This fork of Coffeescript is a trial implementation of monadic do notation, &agrave; la [Haskell](http://www.haskell.org/haskellwiki/Monads).

Monads are useful in Haskell-like pure functional languages to simulate imperative programming features, and to provide for non-functional operations
like I/O in a pure-ish way. Obviously these considerations do not apply to Coffeescript, an imperative language. But since javascript, and hence Coffeescript, are halfway to being functional (albeit very impure) languages, monads do fit reasonably naturally into them.

The immediate motivation for this project is the [continuation-passing style](http://en.wikipedia.org/wiki/Continuation-passing_style) (CPS) of programming required by node.js. While callbacks are relatively natural in javascript and Coffeescript, the syntax and structure can leave something to be desired. It is easy to find oneself nested half a dozen levels deep in callbacks, and the indentation alone is potentially frustrating. Since continuations are a monad, we can use monadic do-blocks to make a series of nested callbacks look more like a &ldquo;normal&rdquo; block of code. If nothing else, the extra indentation goes away.

Basic Usage
------------

The syntax is based on Haskell. In the generic form, using the keyword `mdo`, the programmer has to specify a `bind` function. Here is a simple implementation of the List monad:

```coffeescript
bindArray = (m, f) ->
    mapped = m.map f
    return Array::concat.apply [], mapped

m = mdo bindArray
    (x) <- [1..3]
    (y) <- ['a', 'b']
    [x+y]
```

Here `m` will be equal to `[ '1a', '1b', '2a', '2b', '3a', '3b' ]`---note that this is a way of creating a list comprehension, generally not [convenient](http://brehaut.net/blog/2011/coffeescript_comprehensions) in Coffeescript.

Since the prime motivation is CPS, there is a specialization `cpsdo` that needs no `bind`, and that generates more optimized code. There is also a `cpsrun` construction that creates a continuation monad and applies it to a trivial continuation. Here's a silly example:

```coffeescript
# A monadic return function that takes a value and returns a monadic continuation-callar
cpsreturn = (args...) -> ((f) -> f args...)
cpsrun
    (err, f) <- fs.readFile.bind null, 'foo.txt'
    cpsreturn console.log "read foo"
    (err, g) <- fs.readFile.bind null, 'bar.txt'
    cpsreturn console.log "read bar"
    console.log f + g
```

This deserves a little exposition. In Haskell-ish notation the continuation monad is

    M t = (t -> a) -> a

That is, it's a functional double-dual, a continuation-processor a function whose argument is itself a function taking the base type. In coffeescript that means the right-hand sides of the bindings should evaluate to functions that take a continuation. Since in node.js functions like `readFile` take a continuation as a final argument, we use bind to curry the function into the form we need.

We can easily augment this to include some error-handling (very poor error-handling in this case)

```coffeescript
# This simply stops processing if the condition is true
cpsbreakif = (b) -> 
  if b
    (fn) -> null
  else
    (fn) -> fn()

# As above, but stop if we can't read the file.
cpsrun
    (err, f) <- fs.readFile.bind null, 'foo.txt'
    cpsbreakif err
    cpsreturn console.log "read foo"
    (err, g) <- fs.readFile.bind null, 'bar.txt'
    cpsbreakif err
    cpsreturn console.log "read bar", this
    console.log f + g
```

Syntax
------
Basic syntax should be evident from the examples above. Just a few notes
* The last statement in a monadic do block must be a simple expression. For mdo and cpsdo it should evaluate to the proper monadic type. In cpsrun that can be any expression, although if it is a function will be applied to a trivial continuation.
* The other statements in the do block are monad bindings and variable assignments. They can be of these forms:
  * `(a) <- block`
    The left-hand side can be anything that can appear as the arugments of a function definition. The right-hand side should evaluate to the monadic type.
  * `<- block`
    The same, but with nothing acutally bound.
  * `expression`
    Just like the previous form. The only difference is that with the <- the right-hand side can be a multiline block.
  * `mlet a = expression`
    Assign some non-monadic variable. It translates directly into a simple assignment statement. `mlet` &ldquo;bindings&rdquo; (they&rquo;e really and truly assignments) follow the same scoping rules as ordinary variables in nested functions.
    
