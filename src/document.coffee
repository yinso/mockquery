XmlParser = require '../grammar/xml'
htmlParser = require 'htmlparser2'
{EventEmitter} = require 'events'
_ = require 'underscore'
loglet = require 'loglet'
Node = require './node'
#pretty = require('pretty-data').pd
#Entities = require('html-entities').AllHtmlEntities;
#entities = new Entities()
entities = require './entities'

parse2 = (data) ->
  XmlParser.parse data

class Document
  @createElement: ({element, attributes, children}) ->
    Element = Node.type Node.ELEMENT_NODE
    new Element element, attributes, children
  constructor: (elt) ->
    elementType = Node.type Node.ELEMENT_NODE
    @documentElement =
      if elt instanceof elementType
        elt.setOwnerDocument @
        elt
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
  children: () ->
    [ @documentElement ]
  createElement: ({element, attributes, children}, parent = null) ->
    #console.log 'createElement', element, attributes
    elt = @initialize element, attributes, children, parent
    if element == 'script' # we will flatten out the inner elements.
      html = elt.html()
      elt.empty()
      elt.append html
    elt
  initialize: (tag, attrs, children, parent) ->
    Element = Node.type Node.ELEMENT_NODE
    element = new Element tag, attrs, parent
    for child in children or []
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
    if @documentElement.isFragment()
      @documentElement.html(args...)
    else
      @documentElement.outerHTML(args...)
  toJSON: () ->
    @documentElement.toJSON()
  serialize: (options) ->
    @documentElement.serialize options

Node.register Node.DOCUMENT_NODE, Document

module.exports = Document
