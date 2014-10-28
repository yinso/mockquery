Parser = require '../grammar/selector'
Selector = require '../src/selector'
assert = require 'assert'

describe 'selector parser test', () ->
  it 'can parse element', (done) ->
    try 
      obj = Parser.parse 'a'
      assert.deepEqual obj, {select: [{elt: 'a'}]}
      done null
    catch e
      done e

  it 'can parse id', (done) ->
    try 
      obj = Parser.parse '#this-is-an-id'
      assert.deepEqual obj, {select: [{elt: '*', id: {id: 'this-is-an-id'}}]} # is this right?
      done null
    catch e
      done e

  it 'can parse class', (done) ->
    try 
      obj = Parser.parse '.this-is-a-class'
      assert.deepEqual obj, {select: [{elt: '*', class: {class: 'this-is-a-class'}}]} # is this right?
      done null
    catch e
      done e

  it 'can parse group', (done) ->
    try 
      obj = Parser.parse 'h1, h2, h3,h4,h5,h6'
      assert.deepEqual obj, {select: [{elt: 'h1'}, {elt: 'h2'}, {elt: 'h3'}, {elt: 'h4'}, {elt: 'h5'}, {elt:'h6'}]} # is this right?
      done null
    catch e
      done e

  it 'can parse attribute', (done) ->
    try 
      obj = Parser.parse 'link[rel^="stylesheet"]'
      assert.deepEqual obj, {select: [{elt: "link", attr: {attr: "rel", op: "^=", arg: "stylesheet"}}]} # is this right?
      done null
    catch e
      done e

  it 'can parse attribute not equal', (done) ->
    try 
      obj = Parser.parse 'link[rel!="stylesheet"]'
      assert.deepEqual obj, {select: [{elt: "link", attr: {attr: "rel", op: "!=", arg: "stylesheet"}}]} # is this right?
      done null
    catch e
      done e
      
  it 'can parse :not pseudo selector', (done) ->
    try 
      obj = Parser.parse 'link:not([rel="stylesheet"])'
      assert.deepEqual obj, {select: [{elt: "link", pseudo: {pseudo: 'not', args: [ {attr: "rel", op: "=", arg: "stylesheet"} ] } } ] }
      done null
    catch e
      done e

  # link:not([rel="stylesheet"])
    
