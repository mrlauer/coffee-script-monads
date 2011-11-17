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
ArrayMonad = {
    bind : (m, f) ->
        mapped = m.map f
        return Array::concat.apply [], mapped
    return : x -> [x]
    zero : []
}

m = mdo ArrayMonad
    (x) <- [1..3]
    (y) <- ['a', 'b']
    [x+y]
```

Here `m` will be equal to `[ '1a', '1b', '2a', '2b', '3a', '3b' ]`---note that this is a way of creating a list comprehension, generally not [convenient](http://brehaut.net/blog/2011/coffeescript_comprehensions) in Coffeescript.

Inside the `mdo` block the functions `mbind`, `mreturn`, and `mzero` will be available if `bind`, `return`, and `zero` were defined in the monad object passed in. The first two are, as you should expect, the ordinary bind and return functions of the monad. The third, which does not make sense for all moands, should be a "zero monad" in the sense that 

```coffeescript
mbind mzero, fn === mzero
```

for any `fn`. It can be used as a "break"; see below.

Since the prime motivation is CPS, there is a specialization `cpsdo` that needs no explicit monad, and that generates more optimized code. Here's a silly example:

```coffeescript
# A monadic return function that takes a value and returns a monadic continuation-callar
cpsdo
    (err, f) <- fs.readFile.bind null, 'foo.txt'
    mreturn console.log "read foo"
    (err, g) <- fs.readFile.bind null, 'bar.txt'
    mreturn console.log "read bar"
    console.log f + g
```

This deserves a little exposition. In Haskell-ish notation the continuation monad is

    M t = (t -> a) -> a

That is, it's a functional double-dual, a continuation-processor a function whose argument is itself a function taking the base type. In coffeescript that means the right-hand sides of the bindings should evaluate to functions that take a continuation. Since in node.js functions like `readFile` take a continuation as a final argument, we use `bind` to curry the function into the form we need.

We can easily augment this to include some error-handling (very poor error-handling in this case)

```coffeescript

# As above, but stop if we can't read the file.
cpsrun
    (err, f) <- fs.readFile.bind null, 'foo.txt'
    when err
        console.log "could not read foo"
        mzero
    mreturn console.log "read foo"
    (err, g) <- fs.readFile.bind null, 'bar.txt'
    when err
        console.log "could not read foo"
        mzero
    mreturn console.log "read bar", this
    console.log f + g
```

Syntax
------
Basic syntax should be evident from the examples above. Just a few notes:

* The last statement in a monadic do block must be a simple expression. For mdo and cpsdo it should evaluate to the proper monadic type. In cpsrun that can be any expression, although if it is a function will be applied to a trivial continuation.
* The other statements in the do block are monad bindings and variable assignments. They can be of these forms:
  * `(a) <- block`
    The left-hand side can be anything that can appear as the arugments of a function definition. The right-hand side should evaluate to the monadic type.
  * `<- block`
    The same, but with nothing acutally bound.
  * `expression`
    Just like the previous form. The only difference is that with the <- the right-hand side can be a multiline block.
  * `when condition block`
  * `expression when condition`
    Both of these forms are monad conditionals with no else clause. A simple if-else works fine too, as long as both branches yield monadic objects when evaluated.
  * `mlet (a) <- block`
    Bind some non-monadic variable. This is NOT an assignment, but rather a new binding--if the variable exists in an outer scope it is not changed. That is why the syntax is that of a monadic binding, not an assignment. The parentheses around the parameter(s) are optional

Only one parameter is allowed on the left-hand side of an `mlet` binding, although it can be a complex pattern (an array or object). Any number of parameters are allowed on the left-hand side of a monadic binding, although depending on the monad all but the first may not be bound as you expect. Multiple parameters are meaningful for the Continuation monad, for example, which could be defined with the binding

```coffeescript
cpbind = (m, f) ->
    return (g) -> m ((a...) -> (f a...) g)
```

`this` is bound to whatever it is outside the mdo block.

The monad definition passed to `mdo` must contain a `bind` function. `when` (and other things to come) will work only if it also contains a `return`.


Issues
------
* Nothing is stable yet. I change my mind frequently.
* Variables first defined (i.e. assigned) in the right-hand side of a binding are available to subsequent bindings. I worry that that could be confusing. For example
  ```coffeescript
  cpsdo
    (a) <- Something
    (b) <-
      i = a
      [Something Else]
    (c) <- i
    mreturn result
  ```
  That seems necessary for the CPS monad to be useful, but I worry that it could be confusing. Note that variables first used inside a monadic do block will not leak outside; the blocks are wrapped in a function call and hence get a scope.
* There should be a better way of introducing a whole suite of monadic functions as in Haskell's Control.Monad.

Installation
------------
I have not been properly checking the compiled files into lib; that makes it a little easier for me to recover from silly mistakes. If you want to install you'll have to build. The process is something like this:

```sh
git clone git://github.com/mrlauer/coffee-script-monads.git
cd coffee-script-monads
git checkout monad      # you should already be in that branch
cake build
cake build:parser
cake -p /path/to/install install
```
    
