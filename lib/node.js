// Generated by CoffeeScript 1.4.0
(function() {
  var NodeFactory, loglet,
    __slice = [].slice;

  loglet = require('loglet');

  NodeFactory = (function() {

    function NodeFactory() {}

    NodeFactory.ELEMENT_NODE = 1;

    NodeFactory.ATTRIBUTE_NODE = 2;

    NodeFactory.TEXT_NODE = 3;

    NodeFactory.CDATA_SECTION_NODE = 4;

    NodeFactory.ENTITY_REFERENCE_NODE = 5;

    NodeFactory.ENTITY_NODE = 6;

    NodeFactory.PROCESSING_INSTRUCTION_NODE = 7;

    NodeFactory.COMMENT_NODE = 8;

    NodeFactory.DOCUMENT_NODE = 9;

    NodeFactory.DOCUMENT_TYPE_NODE = 10;

    NodeFactory.DOCUMENT_FRAGMENT_NODE = 11;

    NodeFactory.NOTATION_NODE = 12;

    NodeFactory._types = {};

    NodeFactory._parser = null;

    NodeFactory.register = function(type, ctor) {
      if (this._types.hasOwnProperty(type)) {
        throw {
          error: 'duplicate_node_type',
          type: type,
          value: ctor
        };
      }
      return this._types[type] = ctor;
    };

    NodeFactory.type = function(type) {
      if (this._types.hasOwnProperty(type)) {
        return this._types[type];
      } else {
        throw {
          error: 'unknown_node_type',
          type: type
        };
      }
    };

    NodeFactory.make = function() {
      var args, ctor, type;
      type = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      ctor = this.type(type);
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(ctor, args, function(){});
    };

    NodeFactory.registerParser = function(parser) {
      if (this._parser) {
        throw {
          error: 'duplicate_parser',
          parser: parser
        };
      }
      return this._parser = parser;
    };

    NodeFactory.parser = function() {
      if (!this._parser) {
        throw {
          error: 'parser_unregistered'
        };
      }
      return this._parser;
    };

    NodeFactory.registerSerializer = function(serializer) {
      if (this._serializer) {
        throw {
          error: 'duplicate_serializer',
          serializer: serializer
        };
      }
      return this._serializer = serializer;
    };

    NodeFactory.serializer = function() {
      if (!this._serializer) {
        throw {
          error: 'serializer_unregistered'
        };
      }
      return this._serializer;
    };

    return NodeFactory;

  })();

  module.exports = NodeFactory;

}).call(this);
