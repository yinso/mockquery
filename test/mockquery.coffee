XmlParser = require '../grammar/xml'
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
          parsed = XmlParser.parse data
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

describe 'xml test', () ->

  it 'should parse xml & select', (done) ->
    mockQuery.readFile path.join(__dirname, '../example/testok.xml'), (err, $) ->
      if err
        done err
      else 
        done null
  
  it 'should parse xml & select', (done) ->
    mockQuery.readFile path.join(__dirname, '../example/testerror.xml'), (err, $) ->
      if err
        done err
      else if $('Items Request Errors').length > 0
        done null
      else
        done {error: 'not_selecting_appropriate_error'}
  
describe 'outerHTML test', () ->
  it 'should have outer element', (done) ->
    txt = '<foo><bar>1</bar><baz>2</baz></foo>'
    $ = mockQuery.load txt
    if $('foo').outerHTML() == txt
      done null
    else
      console.error 'not equal', txt, $('foo').outerHTML()
      done {not_equal: txt}

  it 'should have outer element', (done) ->
    txt = '<foo><bar>1</bar><baz>2</baz></foo>'
    $ = mockQuery.load txt
    if $('foo').text() == '12'
      done null
    else
      console.error 'not equal', txt, $('foo').text()
      done {not_equal: txt}
  
  it 'should handle map correctly', (done) ->
    txt = '<p><c>1</c><c>2</c><c>3</c></p>'
    $ = mockQuery.load txt 
    res = $('c').map (i, elt) -> parseInt(@text())
    if res.length != 3
      done {error: 'no_map'}
    else if res.join('') != '123'
      done {error: 'wrong_data'}
    else
      done null
  

