XmlParser = require '../grammar/xml'
htmlParser = require 'htmlparser2'
{EventEmitter} = require 'events'
_ = require 'underscore'
#pretty = require('pretty-data').pd
Entities = require('html-entities').AllHtmlEntities;
entities = new Entities()

parse1 = (data, options = {xmlMode: true}) ->
  stack = []
  current = null
  level = 0
  handler = 
    onopentag: (name, attr) ->
      obj = {element: name, attributes: attr, children: []}
      #console.log 'level: ', level, '<', name
      if current != null 
        current.children.push obj
        stack.push current
      current = obj
      level++
    ontext: (txt) ->
      if level > 0
        current.children.push entities.decode(txt)
    onclosetag: (name) ->
      if stack.length > 0
        current = stack.pop()
      level--
      #console.log 'level: ', level, '>', name
  parser = new htmlParser.Parser handler, options
  parser.write data 
  parser.end() 
  #console.log pretty.json(current)
  current 
  
parse2 = (data) ->
  XmlParser.parse data

class Document
  @parse: (text, options) ->
    new Document parse1(text, options)
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
    val.split(' ')
  setClasses: (classes) ->
    @attr('class', classes.join(' '))
  addClass: (key) ->
    classes = @getClasses()
    classes.push key
    @setClasses classes
  removeClass: (key) ->
    classes = @getClasses()
    @setClasses _.without classes, key
  html: (str) ->
    if arguments.length == 0
      results = []
      for child in @_children
        if typeof(child) == 'string'
          results.push child
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
          buffer.push child
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
        "#{key} = #{@escape(val)}"
    buffers.join(' ')
  empty: () ->
    for child, i in @_children
      if child instanceof Element
        child.empty()
        child._parent = null
    @_children = []
  escape: (str) ->
    JSON.stringify(str.toString())
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
