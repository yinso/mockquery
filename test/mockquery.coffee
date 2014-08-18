Parser = require '../src/parser'
Document = require '../src/document'
Selector = Document.Selector
mockQuery = require '../src/mockquery'
fs = require 'fs'
path = require 'path'

document = null
$ = null
parsed = null
runtime = null

describe 'document test', () ->

  it 'should parse html', (done) ->
    fs.readFile path.join(__dirname, '../example/test.html'), 'utf8', (err, data) ->
      if err
        done err
      else
        try
          html = data
          parsed = Parser.parse data
          done null
        catch e
          done e

  it 'should load document', (done) ->
    try
      document = new Document parsed, {}
      done null
    catch e
      done e

  it 'should use selector', (done) ->
    try
      selector = new Selector '[data-bind]'
      results = selector.run document
      #console.log '*****select:[data-bind]****'
      #for elt in results
        #console.log 'element', elt.tag, elt.data('bind')
      selector = new Selector 'body'
      results = selector.run document
      #console.log results
      done null
    catch e
      done e

  it 'should use coquery', (done) ->
    try
      $ = mockQuery.load(document)
      test.equal 3, $('script[type="text/template"]').length
      done null
    catch e
      done e

