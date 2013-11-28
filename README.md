# MockQuery - A Simple NodeJS jQuery Substitute

Mockquery is a simple jQuery substitute for NodeJS, meant to be used on the server-side.

This is similar to [cheerio](https://github.com/MatthewMueller/cheerio), but is implemented specifically for
[covalent's](http://github.com/yinso/covalent) use cases. That means it's currently a limited mock and doesn't cover
full jQuery's API (nor the selectors yet).

## Installation

    npm install mockquery

## Usage

    mockquery = require 'mockquery'

    $ = mockquery.load <html_fragment_...>

The html fragment currently needs to be based on XHTML rules; i.e. the underlying parser for mockquery doesn't try to parse
everyday html's. This is due to mockquery's goal is for server-side template generation. This can change in the future.

## Supported Selectors

> TODO - Fill in

## Supported Methods

> TODO - Fill in

