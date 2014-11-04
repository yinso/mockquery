# because things reference each other we will declare them here and modify them elsewhere... 

loglet = require 'loglet'

class NodeFactory
  @ELEMENT_NODE: 1
  @ATTRIBUTE_NODE: 2
  @TEXT_NODE: 3
  @CDATA_SECTION_NODE: 4 
  @ENTITY_REFERENCE_NODE: 5
  @ENTITY_NODE: 6
  @PROCESSING_INSTRUCTION_NODE: 7
  @COMMENT_NODE: 8 
  @DOCUMENT_NODE: 9
  @DOCUMENT_TYPE_NODE: 10
  @DOCUMENT_FRAGMENT_NODE: 11
  @NOTATION_NODE: 12
  @_types = {} 
  @_parser = null
  @register: (type, ctor) ->
    if @_types.hasOwnProperty(type)
      throw {error: 'duplicate_node_type', type: type, value: ctor}
    @_types[type] = ctor
    #loglet.warn 'NodeFactory.register', type, ctor, @_types
  @type: (type) ->
    #loglet.warn 'Node.Type', type, @_types[type]
    if @_types.hasOwnProperty(type)
      @_types[type]
    else
      throw {error: 'unknown_node_type', type: type}
  @make: (type, args...) ->
    ctor = @type type
    new ctor args...
  @registerParser: (parser) ->
    if @_parser
      throw {error: 'duplicate_parser', parser: parser}
    @_parser = parser
  @parser: () ->
    if not @_parser
      throw {error: 'parser_unregistered'}
    @_parser
  @registerSerializer: (serializer) ->
    if @_serializer
      throw {error: 'duplicate_serializer', serializer: serializer}
    #loglet.warn 'registerSerializer', serializer
    @_serializer = serializer
  @serializer: () ->
    if not @_serializer
      throw {error: 'serializer_unregistered'}
    @_serializer
  
module.exports = NodeFactory