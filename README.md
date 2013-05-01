# Cuffs.js

Cuffs.js is a tiny library to help with your JavaScript development. Think of it as AngularJS light. You should have a look at the canonical [Todo App example](https://gist.github.com/flashingpumpkin/2724680).

Cuffs.js gives you:

* A context that controllers can subscribe to and push data into
* An ([extensible](https://github.com/caffeinehit/cuffs.js/blob/master/src/bindings.coffee)) templating system based on raw HTML nodes that operate on the context

You can use standard JavaScript data structures for all the rest.

## Dependencies

Cuffs.js relies on [RequireJS](http://requirejs.org/) and its
[Optimizer](http://requirejs.org/docs/optimization.html) as well as jQuery.

## Installation

```bash
cd cuffs && cake build
```

This places two minified JavaScript files into the `build/` directory.
One includes RequireJS and the other is a standalone version of Cuffs.



