
Node = require './node'
entities = require './entities'
loglet = require 'loglet'
#Document = require './document'
#Element = require './element'

# what do we want to do??? we want to 
outerHTML = (node) ->
  Element = Node.type Node.ELEMENT_NODE
  Document = Node.type Node.DOCUMENT_NODE
  buffer = []
  _toHTML(node, buffer)
  buffer.join('')

innerHTML = (node) ->
  Element = Node.type Node.ELEMENT_NODE
  Document = Node.type Node.DOCUMENT_NODE
  buffer = [] 
  for child in node._children
    _toHTML child, buffer
  buffer.join('')

_attrsToString = (attributes = {}) ->
  buffer =
    for key, val of attributes
      if not (val == null or val == undefined)
        "#{key} = \"#{entities.encode(val)}\""
      else
        ''
  buffer.join(' ')
  
_toHTML = (node, buffer) ->
  #loglet.warn '_toHTML', node, buffer
  # text
  if typeof(node) == 'string'
    buffer.push entities.encode node
    return
  # element
  attrStr = _attrsToString node.attributes
  buffer.push '<', node.tag
  if attrStr != ''
    buffer.push ' ', attrStr
  if node._children.length == 0
    buffer.push ' />'
  else
    buffer.push '>'
    for child in node._children
      if typeof(child) == 'string'
        buffer.push entities.encode child
      else
        _toHTML child, buffer
    buffer.push "</#{node.tag}>"

toText = (node) ->
  buffer = []
  _toText node, buffer
  buffer.join ''
  
_toText = (node, buffer) ->
  if typeof(node) == 'string'
    buffer.push node
  else
    for child, i in node._children 
      _toText child, buffer

toJSON = (node) ->
  if typeof(node) == 'string'
    node
  else
    obj = 
      element: node.tag 
      attributes: node.attributes
      children: [] 
    for child in node._children
      obj.children.push toJSON(child)
    obj

fromJSON = (obj, Element = Node.type Node.ELEMENT_NODE) ->
  if typeof(obj) == 'string'
    obj 
  else
    elt = new Element obj.element, obj.attributes or {}, []
    for child in (obj.children or [])
      elt.append fromJSON(child, Element)
    elt
  
Node.registerSerializer module.exports =
  outerHTML: outerHTML
  innerHTML: innerHTML
  toText: toText
  toJSON: toJSON
  fromJSON: fromJSON


