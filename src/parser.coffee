htmlParser = require 'htmlparser2'
{EventEmitter} = require 'events'
_ = require 'underscore'
loglet = require 'loglet'
entities = require './entities'
Node = require './node'

class ParseStack
  constructor: () ->
    @Element = Node.type Node.ELEMENT_NODE
    @root = new @Element '__', {}
    @stack = [ @root ]
  level: () ->
    @stack.length 
  current: () ->
    if @stack.length == 0
      null 
    else
      @stack[@stack.length - 1]
  rootElement: () ->
    children = @root.children()
    if children.length == 1
      children[0]
    else
      @root
  decode: (val) ->
    entities.decode val
  normalizeAttrs: (attrs) ->
    result = {}
    for key, val of attrs 
      result[key] = @decode val
    result
  push: (name, attrs) ->
    @_pushElement new @Element name, @normalizeAttrs(attrs)
  _pushElement: (elt) ->
    if @root == null 
      @root = elt
      @stack.push elt 
    else # we have something on the list... 
      @current().append elt
      @stack.push elt
  pushText: (txt) ->
    if @level() > 0 
      @current().append @decode txt 
  pop: (name) ->
    if @level() > 0 
      @stack.pop() 
  tabify: (count) ->
    ('  ' for i in [0...count]).join('')
  printClose: () ->
    items = 
      for elt, i in @stack 
        @tabify(i) + '</' + elt.element
    for line in items.reverse() 
      loglet.debug 'parseStack.close', line
  printOpen: () ->
    for elt, i in @stack 
      loglet.debug 'parseStack.open', @tabify(i) + '<' + elt.element

parse1 = (data, options = {xmlMode: true}) ->
  parseStack = new ParseStack() 
  handler = 
    onopentag: (name, attr) ->
      parseStack.push name, attr
      parseStack.printOpen()
    ontext: (txt) ->
      parseStack.pushText txt 
    onclosetag: (name) ->
      parseStack.printClose()
      parseStack.pop(name)
  parser = new htmlParser.Parser handler, options
  parser.write data 
  parser.end() 
  parseStack.rootElement() 
  
parseDocument = (text, options) ->
    #loglet.warn 'Document.parse', text, options
    Document = Node.type Node.DOCUMENT_NODE
    document = 
      if typeof(text) == 'string'
        elt = parse1(text, options)
        loglet.debug  'parseDocument', text, elt.outerHTML()
        new Document elt 
      else if text instanceof Object and text.element 
        new Document text
      else
        throw {error: 'unknown_document_structure', document: text}
    document

parseElement = (text, document, options = {xmlMode: true}) ->
  element = parse1 text, options
  element.setOwnerDocument document
  element

parser = 
  parseDocument: parseDocument
  parseElement: parseElement
  
Node.registerParser parser 

module.exports = parser



