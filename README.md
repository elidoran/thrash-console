# @thrash/console

Outputs thrash results to console in a table.


## Install

```sh
npm install @thrash/console --save-dev
```


## Usage

See [@thrash/core](https://github.com/elidoran/thrash-core) to learn how the basics work.

```javascript
var thrash = require('@thrash/fn')
  , thrashIt = thrash 'some-module'

// HERE!
// this is how to apply this plugin to a thrasher.
thrashIt.use('@thrash/console', {
  width: 15,     // column width (padded)
  separator: '|' // column separator
})

// then thrash it a million times with some inputs
thrashIt({ repeat:1e6, with:[ inputs ]})
```

The output will be something similar to the below.

It will show headers showing the column of input values and the other header for the module being thrashed. It is possible to override the module's header by specifying a `label` options property when wrapping it like `thrash('some-module', {label:'my module'})`.

Each input block shows:

1. whether calling the function with the input provided a valid response
2. if the function is optimizable with those inputs
3. how long it took to run the function the number of times specified by `repeat`. It shows both seconds and nanoseconds because the measurement is made using high resolution time tracking via `process.hrtime()`.

```sh
     inputs     |  some-module    
----------------------------------
   123456789012 |          valid
                |    optimizable
                |        3163 s
                |     1041102 ns
----------------------------------
```


## Options

Some options applied when adding the plugin:

1. **width** - the width to pad all columns to.
2. **separator** - defaults to the pipe character `'|'`.
3. **headers** - optional way to specify header labels like `header: [ {label:'some header'}]`. Otherwise, headers are retrieve from the `label` property of the thrasher(s) involved.


## Events

This plugin doesn't add events. It consumes event information and writes a formatted version of it to the console.


### MIT License
