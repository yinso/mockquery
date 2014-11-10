XmlParser = require '../grammar/xml'
Document = require '../src/document'
Selector = require '../src/selector'
mockQuery = require '../src/mockquery'
fs = require 'fs'
path = require 'path'
assert = require 'assert'
loglet = require 'loglet'

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
        #console.log 'ITEMS REQUEST ERRORS', $('Items Request Errors')
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

describe 'encode/decode test', () ->
  txt = '<p id = "&quot;Hello World&quot;">This is &lt;a test&gt;</p>'
  $ = null
  it 'should decode text', (done) ->
    try 
      $ = mockQuery.load txt 
      assert.equal $('p').text(), 'This is <a test>'
      done null
    catch e
      done e
  
  it 'should decode text', (done) ->
    try 
      assert.equal $('p').html(), 'This is &lt;a test&gt;'
      done null
    catch e
      done e
  
  it 'should decode attr', (done) ->
    try
      assert.equal $('p').attr('id'), '"Hello World"'
      done null
    catch e
      done e

  it 'should decode everything', (done) ->
    try
      assert.equal $('p').outerHTML(), txt
      done null
    catch e
      done e
      
  it 'should parse h1 successfully', (done) ->
    try 
      data = '<h2 id = \"marketing-1-knowledge\">Knowledge</h2>\n<p>This is the first marketing piece.</p>\n'
      $ = mockQuery.load data
      assert.equal $('h1,h2,h3,h4,h5,h6').text(), 'Knowledge'
      done null
    catch e
      done e
  
  it 'should deal with fragment successfully', (done) ->
    try 
      data = '<h2 id = \"marketing-1-knowledge\">Knowledge</h2>\n<p>This is the first marketing piece.</p>\n'
      $ = mockQuery.load data
      assert.equal data, $($.document).outerHTML()
      done null
    catch e
      done e
  
  it 'should create element', (done) ->
    try
      $ = mockQuery.load('<div></div>') 
      elt = $('<div />', {class: 'test me out'})[0]
      assert.equal 'test me out', $(elt).attr('class')
      done null
    catch e
      done e
  
  it 'should allow us to swap out root nodes', (done) ->
    try 
      data = '<bar>1</bar><baz>1</baz><xyz>2</xyz>'
      $ = mockQuery.load data
      
      elt = $('<div />')[0]
      $(elt).append $(':root').children()
      #loglet.warn 'item.children', $(':root').children(), $.document.documentElement
      assert.equal $(elt).outerHTML(), '<div>' + data + '</div>'
      done null
    catch e 
      done e
  
  it 'can set html without issues', (done) ->
    try 
      data = '<foo><bar>1</bar><baz>2</baz></foo>'
      snippet = '<abc>1</abc><def>2</def>'
      $ = mockQuery.load data 
      $('foo').html(snippet)
      #loglet.warn 'set html', $('foo')[0]
      assert.equal $('foo').html(), snippet
      done null
    catch e
      loglet.error e
      done e
    
  it 'can createElement', (done) ->
    try 
      elt = mockQuery.Document.createElement {
        element: 'h1'
        attributes: {class: 'test'}
        children: [ "hello world"]
      }
      assert.equal elt.outerHTML(), '<h1 class = "test">hello world</h1>'
      done null
    catch e
      done e
  
  it 'can deserialize from JSON', (done) ->
    try
      $ = mockQuery.fromJSON 
        element: 'p'
        attributes: {}
        children: 
          [
            'This is a test '
            { 
              element: 'a'
              attributes: 
                href: 'http://google.com'
              children: 
                [
                  'To Google'
                ]
            }
            ' we can see it now'
          ]
      
      assert.equal $('p').outerHTML(), '<p>This is a test <a href = "http://google.com">To Google</a> we can see it now</p>'
      done null 
    catch e
      done e
  
  it 'can serialize into numeric entity', (done) ->
    try
      data = '<foo>abc &lt; &trade; &reg; &gt; etc...</foo>'
      $ = mockQuery.load data 
      assert.equal $.document.serialize({numericEntity: true}), '<foo>abc &lt; &#8482; &#174; &gt; etc...</foo>'
      done null
    catch e
      done e
  
  it 'can serialize only basic entity', (done) ->
    try
      data = '<foo>abc &lt; &trade; &reg; &gt; etc...</foo>'
      $ = mockQuery.load data 
      assert.equal $.document.serialize({basicEntity: true}), '<foo>abc &lt; ™ ® &gt; etc...</foo>'
      done null
    catch e
      done e


