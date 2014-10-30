loglet = require 'loglet'

class Entities
  constructor: () ->
    @decodeMap = {}
    @encodeMap = {} 
    @encodeRegex = //
  register: (entity, txt) ->
    normed = @normalize entity
    @decodeMap[ normed ] = txt
    @encodeMap[ txt] = "&#{normed};"
    @_buildEncodeRegex() 
    loglet.debug 'Entities.register', @encodeRegex, @encodeMap, @decodeMap
  unicode: (num) ->
    # total of 4 characters... 
    hex = num.toString 16
    if hex.length < 4 
      '\\u' + ('0' for i in [0...(4 - hex.length)]).join('') + hex
    else
      '\\u' + hex
  _buildEncodeRegex: () ->
    keys = 
      for key, val of @encodeMap 
        #@unicode key.charAt(0)
        '\\' + key
    @encodeRegex = new RegExp keys.join('|'), 'g'
  registerEntities: (entities) ->
    for [ entity, txt ] in entities
      @register entity, txt
  normalize: (entity) ->
    entity.replace /^&([^;]+);$/, '$1'
  decode: (txt) ->
    self = @ 
    txt.replace /&([^;]+);/g, (match, p1) ->
      loglet.debug 'entities.decode', txt, match, p1
      if self.decodeMap.hasOwnProperty(p1)
        self.decodeMap[p1]
      else if p1.match /^#\d+$/ # pure number... 
        code = parseInt(p1.substring(1))
        char = String.fromCharCode code
        loglet.debug 'entities.decode.charCode', code, char
        char
      else if p1.match /^#x[0-9a-fA-F]+$/
        code = parseInt('0' + p1.substring(1))
        char = String.fromCharCode code
        loglet.debug 'entities.decode.hexCode', code, char
        char
      else
        throw new Error("unknown_html_entity #{match}")
  encode: (txt) ->
    # what is a fast way to 
    # in order to encode... what is the fast way to do so? 
    self = @
    txt.replace @encodeRegex, (match) ->
      loglet.debug 'encode', match, self.encodeMap[match]
      if self.encodeMap.hasOwnProperty(match)
        self.encodeMap[match]
      else
        match # just return itself... though shouldn't be here anyways... 

entities = new Entities()

defaultEntities = 
  [
    [ '&amp;', '&' ]
    [ '&lt;', '<' ]
    [ '&gt;', '>' ]
    [ '&quot;', '"' ]
    [ '&apos;', "'" ]
    [ '&nbsp;', String.fromCharCode(160) ]
    [ '&iexcl;', '¡' ]
    [ '&cent;', '¢' ]
    [ '&pound;', '£' ]
    [ '&curren;', '¤' ]
    [ '&copy;', '©']
    [ '&reg;', '®']
  ]

entities.registerEntities defaultEntities

module.exports = entities
