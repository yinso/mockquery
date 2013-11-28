# MockQuery - A Simple NodeJS jQuery Substitute

`Mockquery` is a simple jQuery substitute for NodeJS, meant to be used on the server-side.

This is similar to [cheerio](https://github.com/MatthewMueller/cheerio), but is implemented specifically for
[covalent's](http://github.com/yinso/covalent) use cases. That means it's currently a limited mock and doesn't cover
full jQuery's API (nor the selectors yet).

## Installation

    npm install mockquery

## Usage

You can create the `$` object via loading an HTML fragment.

    var mockquery = require('mockquery')

    var $ = mockquery.load('<div>an html fragment</div>');

The html fragment currently needs to be based on XHTML rules; i.e. the underlying parser for mockquery doesn't try to parse
everyday html's. This is due to mockquery's goal is for server-side template generation. This can change in the future.

You can also directly load from a file with either `readFile` (async) or `readFileSync` method.

    // default async method
    mockquery.readFile(<filePath>, function(err, $) {
      if (err) {
       ...
      } else {
        // use $ as the jQuery object.
      }
    });

    // sync method
    $ = mockquery.readFileSync(<filePath>);


## Document Object Model

`mockquery` provides a very limited DOM to keep things light, and just enough to support the mutators that makes sense
for the server-side. Use `$` for manipulation rather than DOM methods, since it's not a goal to be DOM-compliant.

### Document Object

Once the document is loaded, the `document` object is available as `$.document`. This is a very limited document object.
You generally do not want to directly manipulate it as a DOM object. Instead - use `$` for manipulation.

### Element Object

The `Element` object is likewise limited, and designed for template use (i.e. modifying attributes and children elements).
You are likely to hold onto references of them, but use `$` for manipulation.

## `getJSON` and `postJSON`

Both `$.getJSON` and `$.postJSON` are available, and they are stubbed out, since for template generation you likely not
want to prepopulate data that's supposed to be pulled from the client-side.

## Supported Selectors

Since this is developed to support [covalent](http://github.com/yinso/covalent) it means that currently the selector
supported are based on the need of `covalent`. This can be improved in the future if there are needs.

You can pass `element` or `document` objects into `$` - the same way as in jQuery.

    $(<element>)
    $(<document>)

Likewise - you can also use element tags.

    $('body')
    $('div')

Class and ID also work.

    $('.class')
    $('#id')

Attributes also work.

    $('[href]')

You can also create more elements via passing in a html fragment.

    $('<div>a html fragment</div>')

## Supported jQuery Methods

### Data Methods

    $(<selector>).data(<key>)

    $(<selector>).data(<key>, <val>)

`.data()` works the same as `jQuery.data()`. You can use it to hold complex object (it won't be serialized into string;
this is the same behavior as `jQuery`.

### Attribute Methods

    $(<selector>).attr(<key>)

    $(<selector>).attr(<key>, <val>)

    $(<selector>.removeAttr(<key>)

### CSS Methods

    $(<selector>).addClass(<class>)

    $(<selector>).removeClass(<class>)

    $(<selector>.css(<key>)

    $(<selector>).css(<key>, <val>)

    $(<selector>).css(<object>)

### innerHTML and Child Elements Methods

    $(<selector>).html()

    $(<selector>).html('<div>another fragment</div>')

    $(<selector>).children()

    $(<selector>).append(<element>)

    $(<element>).appendTo(<selector>)

    $(<selector>).prepend(<element>)

    $(<selector>).after(<element>)

    $(<selector>).detach()

    $(<selector>).remove()

    $(<selector>).empty()

    $(<selector>).clone()

### Subsequent Selector Methods

    $(<selector>).add(<selector>, <context>)

    $(<selector>).filter(<selector_2>)

    $(<selector>).has(<selector_2>)

    $(<selector>).not(<selector>)

### Event Methods

Events are all stubbed, like `.getJSON` and `.postJSON`.

    $(<selector>).bind(<event>, ...) // does nothing

    $(<selector>).unbind(<event>, ...) // does nothing

    $(<selector>).on(<event>, ...) // does nothing

### Helper Methods


    $(<selector>).index()

    $(<selector>).toArray()

    $(<selector>).val()



