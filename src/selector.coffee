Document = require './document'
Parser = require '../grammar/selector'

class Selector
  @parse: (stmt) ->
    new Selector stmt
  constructor: (stmt) ->
    {@select} = Parser.parse stmt #"#{stmt} { @text: '' }"
    @matchExp = @compile @select
  negate: () ->
    origMatchExp = @matchExp
    @matchExp = (element) ->
      not origMatchExp(element)
    @select.not = if @select.hasOwnProperty('not') then not @select.not else true
  run: (elt, includeSelf = false) ->
    result = []
    @match elt, result, includeSelf
    result
  match: (element, result, includeSelf = false) ->
    #console.log 'selector.match', element
    if element instanceof Document
      element = element.documentElement
    if includeSelf
      @matchOne element, result
    for child in element.children()
      @match child, result, true
  matchOne: (element, result) ->
    res = @matchExp element
    #console.log '@matchOne', @select, res, element.eltHTML(), @matchExp.toString()
    if res
      result.push element
      true
    else
      false
  compile: (selectExp) ->
    #console.log 'Selector.compile', selectExp
    if selectExp instanceof Array # this is a group (it's an OR).
      @compileArray selectExp
    else
      @compileOne selectExp
  compileArray: (selectExp) ->
    matchExps =
      for inner in selectExp
        @compile inner
    (element) =>
      #console.log 'matchArray', element.tag
      for match in matchExps
        if match(element)
          return true
      return false
  compileOne: (exp) ->
    #console.log 'compileOne', exp
    eltExp = @compileTag(exp.elt)
    idExp = @compileID(exp.id)
    classExp = @compileClass(exp.class)
    attrExp = @compileAttr(exp.attr)
    pseudoExp = @compilePseudo(exp.pseudo)
    (element) -> # why didn't this run????
      #console.log 'matchOne', element.tag
      eltExp(element) and idExp(element) and classExp(element) and attrExp(element) and pseudoExp(element)
  compileTag: (tag) ->
    if tag == '*'
      (element) ->
        #console.log 'isAnyElement', element.tag, tag
        true
    else
      (element) ->
        #console.log 'isElement', element.tag, tag, element.tag == tag
        element.tag == tag
  compileID: (id) ->
    if id instanceof Array
      (element) ->
        _.contains id, element.attributes['id']
    else if typeof(id) == 'string'
      (element) ->
        element.attributes['id'] == id
    else
      (element) ->
        true
  compileClass: (classes) ->
    if classes instanceof Array
      classExps =
        for cls in classes
          @compileOneClass cls
      (element) ->
        for classExp in classExps
          if classExp(element)
            return true
        return false
    else if typeof(classes) == 'string'
      @compileOneClass classes
    else
      (element) ->
        true
  compileOneClass: (cls) ->
    (element) ->
      eltClasses = element.getClasses()
      _.contains eltClasses, cls
  compileAttr: (attrs) ->
    if attrs instanceof Array
      attrExps =
        for attr in attrs
          @compileOneAttr attr
      (element) ->
        for attrExp in attrExps
          if not attrExp(element)
            return false
        return true
    else if attrs instanceof Object
      @compileOneAttr attrs
    else
      (element) -> true
  compileOneAttr: ({attr, op, arg}) ->
    # op can be one of the following: '=' / '~=' / '^=' / '$=' / '*=' / '|='
    #console.log 'compileOneAttr', attr, op, arg
    valExp =
      if arg
        if op == '=' # this is an equal comparison.
          (attr) -> attr == arg
        else if op == '~='
          regex = new RegExp arg
          (attr) -> attr.match regex
        else if op == '^='
          regex = new RegExp "^#{arg}"
          (attr) -> attr.match regex
        else if op == "$="
          regex = new RegExp "#{arg}$"
          (attr) -> attr.match regex
        else if op == '!=' # extension... 
          #console.log 'not equal'
          (attr) -> 
            #console.log attr, 'not equal', arg, '?'
            attr != arg
        else
          throw new Error("unsupported_attribute_selector: #{attr}#{op}#{arg}")
      else
        (attr) -> true
    (element) ->
      if not element.attributes.hasOwnProperty(attr)
        return false
      valExp element.attributes[attr]
  compilePseudo: (pseudos) ->
    if pseudos instanceof Array
      pseudoExps = 
        for pseudo in pseudos
          @compileOnePseudo pseudo
      (element) ->
        for pseudoExp in pseudoExps 
          if not pseudoExp(element)
            return false
        return true
    else if pseudos instanceof Object
      @compileOnePseudo pseudos
    else 
      (element) -> true
  compileOnePseudo: ({pseudo, args}) ->
    #console.log 'compileOnePseudo', pseudo, args
    if pseudo== 'not' # this one is special... 
      arg = args[0]
      innerExp = 
        if arg.id 
          @compileID arg
        else if arg.class
          @compileClass arg
        else if arg.attr
          @compileAttr arg
        else
          @compilePseudo arg
      (elt) -> 
        res = innerExp(elt)
        #console.log 'pseudoInner', pseudo, args, res, not res
        not res
    else
      throw {pseudo_not_supported: pseudo, args: args}

module.exports = Selector
