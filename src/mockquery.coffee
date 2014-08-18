_ = require 'underscore'
{EventEmitter} = require 'events'
Document = require './document'
Element = Document.Element
Selector = Document.Selector
Parser = require './parser'
http = require 'http'
https = require 'https'
url = require 'url'
kvs = require './kvs'
qs = require 'querystring'
fs = require 'fs'
path = require 'path'

class MockQuery
  constructor: (elements, @context) ->
    for elt, i in elements
      @[i] = elt
      @length = elements.length
  html: (htmlString) ->
    if arguments.length == 0
      if @length > 0
        @[0].html()
      else
        null
    else
      for elt, i in @
        elt.html htmlString
      @
  attr: (key, val) ->
    if arguments.length == 1
      if @length > 0
        return @[0].attr(key)
      else
        return null
    else
      for elt in @
        elt.attr(key, val)
      @
  bind: (args...) ->
    for elt, i in @
      elt.bind args...
    @
  unbind: (args...) ->
    for elt, i in @
      elt.unbind args...
    @
  css: (arg...) ->
    if arguments.length == 1
      if @length > 0
        return @[0].css arg[0]
      else
        return null
    else
      for elt, i in @
        elt.css arg...
      @
  addClass: (cls) ->
    for elt, i in @
      elt.addClass cls
    @
  removeClass: (cls) ->
    for elt, i in @
      elt.removeClass cls
    @
  children: () ->
    if @length == 0
      new MockQuery [], @context
    else
      new MockQuery @[0].children(), @context
  appendTo: (parent) ->
    for elt, i in @
      parent.append elt
    @
  detach: () -> # not sure what detach means... It means it's not deleted...
    for elt, i in @
      elt.detach()
    @
  removeAttr: (key) ->
    for elt, i in @
      elt.removeAttr(key)
    @
  empty: () ->
    for elt, i in @
      elt.empty()
    @
  on: () ->
    @
  filter: (selector) ->
    #console.log 'jQuery.filter', selector
    selector = new Selector selector
    result = []
    for elt, i in @
      if elt instanceof Document
        selector.matchOne elt.documentElement, result
      else
        selector.matchOne elt, result
    new MockQuery result, @context
  add: (selector, context = @context) ->
    sel = new Selector selector
    results = sel.run context
    new MockQuery @toArray().concat(results), @context
  toArray: () ->
    elt for elt in @
  has: (selector) ->
    if selector instanceof Element
      for elt in @
        if elt == selector
          return new MockQuery [ elt ], @context
      return new MockQuery [], @context
    else
      selector = new Selector selector
      result = []
      for elt in @
        selector.match elt, result
      return new MockQuery result, @context
  data: (key, val) ->
    if arguments.length == 1
      if @length == 0
        null
      else
        @[0].data key
    else
      for elt, i in @
        elt.data key, val
  remove: () ->
    for elt, i in @
      elt.detach() # we should also remove the objects from the list???
    @
  clone: () ->
    elements =
      for elt, i in @
        elt.clone()
    new MockQuery elements, @context
  not: (selector) ->
    if selector instanceof Array
      result = []
      for elt, i in @
        if not _.contains(selector, elt)
          result.push elt
      new MockQuery result, @context
    else if typeof(selector) == 'string'
      sel = new Selector selector
      result = []
      for elt, i in @
        res = sel.matchOne elt, result
        #console.log '@jQuery.not', selector, elt.eltHTML(), res
        if not res
          result.push elt
      #console.log 'jQuery.not', result
      new MockQuery result, @context
    else
      throw new Error("unsupported_not_selector: #{selector}")
  prepend: (element) ->
    # we'll have to clone the element.
    for elt, i in @
      if i == 0
        elt.prepend element
      else
        elt.prepend element.clone()
    @
  append: (element) ->
    for elt, i in @
      if i == 0
        elt.append element
      else
        elt.append element.clone()
    @
  after: (element) ->
    for elt, i in @
      elt.after element
    @
  val: (value) ->
    if arguments.length == 0
      if @length > 0
        @[0].val()
    else
      for elt, i in @
        elt.val(value)
      @
  index: () ->
    if @length == 0
      null
    else
      if not @[0]._parent
        0
      else
        # determine where the elt is in relation to the parent.
        @[0]._parent.children().indexOf(@[0])


statusCodeToError = (statusCode) ->
  if statusCode >= 500
    new Error("server_error: #{statusCode}")
  else if statusCode >= 400
    new Error("bad_request: #{statusCode}")
  else if statusCode >= 300
    null
  else if statusCode >= 200
    null
  else
    null

getJSON = (uri, data, cb) ->
  ###
  if arguments.length == 2
    cb = data
    data = {}
  try
    data = kvs.flatten data
    options = url.parse uri
    options.query = _.extend {}, options.query, data
    console.log 'getJSON', uri, options
    protocol =
      if options.protocol == 'https:'
        https
      else if options.protocol == 'http:'
        http
      else
        throw new Error("unsupported_protocol: #{uri}")
    req = protocol.request options, (res) ->
      output = []
      res.setEncoding 'utf8'
      res.on 'data', (chunk) ->
        console.log 'getJSON.response.chunk', chunk
        output.push chunk
      res.on 'end', () ->
        try
          obj = JSON.parse output.join('')
          console.log 'getJSON.response.end', obj
          cb obj, res.statusCode
        catch e
          cb e, 500
    req.on 'error', cb
  catch e
    cb e, 500
  ###

postJSON = (uri, data, cb) ->
  ###
  if arguments.length == 2
    cb = data
    data = {}
  try
    data = kvs.flatten data
    options = url.parse uri
    protocol =
      if options.protocol == 'https'
        https
      else if options.protocol == 'http'
        http
      else
        throw new Error("unsupported_protocol: #{uri}")
    req = protocol.request options, (res) ->
      output = []
      res.setEncoding 'utf8'
      res.on 'data', (chunk) ->
        output.push chunk
      res.on 'end', () ->
        try
          obj = JSON.parse output.join('')
          cb obj, res.statusCode
        catch e
          cb e, 500
    req.on 'error', cb
    query = qs.stringify(data)
    req.setHeader 'Content-Type', 'application/x-www-form-urlencoded'
    req.setHeader 'Content-Length', query.length
    req.write query
    req.end()
  catch e
    cb e, 500
  ###

load = (document) ->
  if typeof(document) == 'string'
    document = new Document document
  query = (selector, context = document) ->
    if selector instanceof Element
      new MockQuery [selector], document
    else if selector instanceof Document
      new MockQuery [selector], document
    else if typeof(selector) == 'string' and selector.match(/<[^>]+>/)
      elt = document.createElement Parser.parse('<div>'+ selector + '</div>')
      new MockQuery elt.children(), document
    else if typeof(selector) == 'string'
      sel = new Selector selector
      new MockQuery sel.run(document, false), document
    else
      throw new Error("unknown_selector_type: #{selector}")
  query.fn = query.prototype
  query.document = document
  query.fn.getJSON = getJSON
  query.fn.destroy = () ->
    query.document.destroy()
  query

readFile = (filePath, cb) ->
  fs.readFile filePath, 'utf8', (err, data) ->
    if err
      cb err
    else
      cb null, load(data)

readFileSync = (filePath) ->
  load fs.readFileSync filePath, 'utf8'

module.exports =
  load: load
  readFile: readFile
  readFileSync: readFileSync
