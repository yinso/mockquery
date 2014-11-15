XmlParser = require '../grammar/xml'
htmlParser = require 'htmlparser2'
{EventEmitter} = require 'events'
_ = require 'underscore'
loglet = require 'loglet'
Node = require './node'
entities = require './entities'
Document = require './document'

#
# I've already have the selector parsed... actually the selector ought to be decently simple.
# it might as well just be a function
#
class Element extends EventEmitter
  constructor: (tag, attributes, children = []) ->
    @tag = tag
    @attributes = attributes
    @_data = {}
    @_children = []
    for child in children 
      @append child
  isFragment: () ->
    @tag == '__'
  destroy: () ->
    delete @ownerDocument
    delete @_parent
    for child in @_children
      if child instanceof Element
        child.destroy()
    delete @_children
  clone: () -> 
    documentType = Node.type Node.DOCUMENT_NODE
    elt = new Element @tag, _.extend({}, @attributes)
    if @ownerDocument instanceof documentType 
      elt.setOwnerDocument @ownerDocument
    for child in @_children
      if child instanceof Element
        elt.append child.clone()
      else
        elt.append child
    elt
  setOwnerDocument: (doc) ->
    documentType = Node.type Node.DOCUMENT_NODE
    if not (doc instanceof documentType)
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
      @_children.splice(index + 1, 0, elt)
    else
      @_children.push elt
    #loglet.warn 'Element.append', elt, @
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
      Node.serializer().innerHTML @
    else # we are *setting* the value.
      elt = Node.parser().parseElement '<div>' + str + '</div>', @ownerDocument
      @empty()
      for child in elt._children
        @append child 
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
  outerHTML: () ->
    Node.serializer().outerHTML @
  text: () ->
    if arguments.length == 0
      Node.serializer().toText @
    else
      @empty()
      @append arguments[0].toString()
  toJSON: () ->
    Node.serializer().toJSON @
  serialize: (options) ->
    Node.serializer().outerHTML @, options
  hasBinding: () ->
    @bindings != null
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

Node.register Node.ELEMENT_NODE, Element

Document.Element = Element

module.exports = Element

#Document.Selector = Selector
