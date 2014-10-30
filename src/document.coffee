XmlParser = require '../grammar/xml'
htmlParser = require 'htmlparser2'
{EventEmitter} = require 'events'
_ = require 'underscore'
loglet = require 'loglet'
#pretty = require('pretty-data').pd
#Entities = require('html-entities').AllHtmlEntities;
#entities = new Entities()
entities = require './entities'

class ParseStack
  constructor: () ->
    @root = {element: '__', attributes: {}, children: []} # this is a pseudo element.
    @stack = [ @root ]
  level: () ->
    @stack.length 
  current: () ->
    if @stack.length == 0
      null 
    else
      @stack[@stack.length - 1]
  rootElement: () ->
    children = _.filter @root.children, (elt) -> elt instanceof Object
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
    @_pushElement {
      element: name 
      attributes: @normalizeAttrs attrs
      children: [] 
    }
  _pushElement: (elt) ->
    if @root == null 
      @root = elt
      @stack.push elt 
    else # we have something on the list... 
      @current().children.push elt
      @stack.push elt
  pushText: (txt) ->
    if @level() > 0 
      @current().children.push @decode txt 
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
  
parse2 = (data) ->
  XmlParser.parse data

class Document
  @parse: (text, options) ->
    if typeof(text) == 'string'
      new Document parse1(text, options)
    else if text instanceof Object and text.element 
      new Document text
    else
      throw {error: 'unknown_document_structure', document: text}
  constructor: (elt) ->
    @documentElement =
      if elt instanceof Element
        elt.setOwnerDocument @
      else
        elt = @createElement elt
        elt.setOwnerDocument @
        elt
    @_data = {}
  destroy: () ->
    @documentElement.destroy()
  data: (key, val) ->
    if arguments.length == 1
      res = @_data[key]
      if res
        res
      else
        undefined
    else
      @_data[key] = val
  createElement: ({element, attributes, children}, parent = null) ->
    #console.log 'createElement', element, attributes
    elt = @initialize element, attributes, children, parent
    if element == 'script' # we will flatten out the inner elements.
      html = elt.html()
      elt.empty()
      elt.append html
    elt
  initialize: (tag, attrs, children, parent) ->
    element = new Element tag, attrs, null, parent
    for child in children
      if typeof(child) == 'string'
        element.append child
      else
        childElement = @createElement child, element
        element.append childElement
    element.setOwnerDocument @
    element
  bind: (args...) ->
  on: (args...) ->
  unbind: (args...) ->
  clone: () ->
    new Document @documentElement.clone()
  html: (args...) ->
    @documentElement.html args...
  outerHTML: (args...) ->
    @documentElement.outerHTML(args...)

#
# I've already have the selector parsed... actually the selector ought to be decently simple.
# it might as well just be a function
#
class Element extends EventEmitter
  constructor: (tag, attributes, @_parent, @ownerDocument) ->
    @tag = tag
    @attributes = attributes
    @_data = {}
    @_children = []
  destroy: () ->
    delete @ownerDocument
    delete @_parent
    for child in @_children
      if child instanceof Element
        child.destroy()
    delete @_children
  clone: () -> # when we clone do we worry about the current parent?
    elt = @ownerDocument.createElement {element: @tag, attributes: _.extend({}, @attributes), children: []}
    for child in @_children
      if child instanceof Element
        elt.append child.clone()
      else
        elt.append child
    elt
  setOwnerDocument: (doc) ->
    if not (doc instanceof Document)
      throw new Error("element.setOwnerDocument_not_document: #{doc}")
    @ownerDocument = doc
    for child in @_children
      if child instanceof Element
        child.setOwnerDocument(doc)
  parent: () ->
    @_parent
  children: () ->
    _.filter @_children, (elt) -> elt instanceof Element
  removeChild: (element) ->
    @_children = _.without @_children, element
    element._parent = null
  detach: () ->
    if @_parent
      @_parent.removeChild @
  append: (elt, after) ->
    if elt instanceof Element
      elt.detach()
      elt._parent = @
    if after
      index = @_children.indexOf(after)
      @_children.splice(index, 0, elt)
    else
      @_children.push elt
  prepend: (elt, before) ->
    if elt instanceof Element
      elt.detach()
      elt._parent = @
    if before
      index = @_children.indexOf(before) - 1
      if index > -1
        @_children.splice index, 0, elt
      else
        @_children.unshift elt
    else
      @_children.unshift elt
  after: (elt) ->
    @_parent.append elt, @
  attr: (key, val) ->
    if arguments.length == 1
      if @attributes.hasOwnProperty(key)
        return @attributes[key]
      else
        undefined
    else
      @attributes[key] = val
  removeAttr: (key) ->
    delete @attributes[key]
  data: (key, val) ->
    if arguments.length == 1
      res = @attr("data-#{key}")
      if res
        res
      else
        @_data[key]
    else
      @_data[key] = val
  getClasses: () ->
    val = @attr('class')
    if val 
      val.split /\s+/
    else 
      []
  setClasses: (classes) ->
    @attr('class', classes.join(' '))
  addClass: (key) ->
    classes = @getClasses()
    classes.push key
    @setClasses classes
  removeClass: (key) ->
    classes = @getClasses()
    @setClasses _.without classes, key
  isWhitespace: (str) ->
    if typeof(str) == 'string'
      str.trim() == ''
    else
      true
  html: (str) ->
    if arguments.length == 0
      results = []
      for child in @_children
        if typeof(child) == 'string'
          if @isWhitespace child
            results.push child
          else
            results.push @escape child
        else
          results.push child.outerHTML()
      results.join('')
    else # we are *setting* the value.
      elt = parse1 '<div>' + str + '</div>'
      @empty()
      # we should have ownerDocument to figure things out...
      for child in elt.children
        if typeof(child) == 'string'
          @append child
        else
          @append @ownerDocument.createElement child, @
  getCSS: () ->
    result = {}
    for keyval in @attr('style').split(/\s*;\s*/)
      [key, val] = keyvals.split(/\s*=\s*/)
      result[key] = val
    result
  setCSS: (keyvals) ->
    result = []
    for key, val of keyvals
      result.push = "#{key}=#{val}"
    @attr('style', result.join(";"))
  css: (key, val) ->
    if arguments.length == 0
      throw new Error(".css_expects_at_least_1_arg")
    else if arguments.length == 1
      if typeof(key) == 'string'
        result = @getCSS()
        result[key]
      else if key instanceof Object
        @setCSS key
      else
        throw new Error("unsupported_css_argument: #{key}")
    else
      keyvals = @getCSS()
      keyvals[key] = val
      @setCSS keyvals
  outerHTML: (buffer = []) ->
    attrStr = @attrsToString()
    buffer.push "<", @tag
    if attrStr != ''
      buffer.push ' ', attrStr
    if @_children.length == 0
      buffer.push ' />'
    else
      buffer.push '>'
      for child in @_children
        if typeof(child) == 'string'
          buffer.push @escape child
        else
          buffer.push child.outerHTML()
      buffer.push "</#{@tag}>"
    buffer.join('')
  eltHTML: () ->
    "<#{@tag} #{@attrsToString()} />"
  text: (buffer = []) ->
    for child, i in @_children 
      if child instanceof Element
        child.text buffer
      else
        buffer.push child
    buffer.join ''
  hasBinding: () ->
    @bindings != null
  attrsToString: () ->
    buffers =
      for key, val of @attributes
        if not (val == null or val == undefined)
          "#{key} = \"#{@escape(val)}\""
        else
          ''
    buffers.join(' ')
  empty: () ->
    for child, i in @_children
      if child instanceof Element
        child.empty()
        child._parent = null
    @_children = []
  escape: (str) ->
    entities.encode(str.toString())
    #JSON.stringify(str.toString())
  bind: (args...) ->
  unbind: (args...) ->
  on: (args...) ->
  val: (value) ->
    if arguments.length == 0
      if @tag == 'input' or @tag == 'textarea' or @tag == 'select'
        if @attributes.hasOwnProperty('value')
          @attributes['value']
        else
          undefined
    else
      if @tag == 'input' or @tag == 'textarea' or @tag == 'select'
        @attributes.value = value
      else
        return

Document.Element = Element


#Document.Selector = Selector

module.exports = Document
