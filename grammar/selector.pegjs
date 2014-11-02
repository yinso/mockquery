/**********************************************************************

Mockquery Parser. It parses XHTML and CSS Selector.

Number
------

1
1.5

String
------

"this is a string"
'this is a string'

Object
------

{foo: 1, bar: "hello", baz: {nested: true}}


Identifier
----------

thisIsAnIdentifier


Reference (referring to proxy value)
---------

$this.is.a.reference

$use.number.for.array.index.1


Element
-------

this.val ==> $(@element).val()

this.html => $(@element).html()

this.<attr> => $(@element).attr('attr')

The above can appear on both LHS or RHS

**********************************************************************/

/**********************************************************************
Preamble
**********************************************************************/
{

function leftAssociative (lhs, rest) {
  if (rest.length == 0) {
    return lhs;
  }
  // if we are going to rewrite the whole thing... do we want to do the same as before??
  // or actually return the operator?
  // let's give it a shot.
  var i = 0;
  var result = lhs;
  // console.log('leftAssociative', JSON.stringify(lhs), JSON.stringify(rest));
  for (i = 0; i < rest.length; ++i) {
     var next = rest[i];
     result = {op: next.op, lhs: result, rhs: next.rhs};
     // console.log('leftAssociative', i, JSON.stringify(result));
  }
  return result;
}

function makeString(head, rest) {
  return [head].concat(rest).join('');
}

function normalizeHelper(elt, key, mod) {
  if (elt[key]) {
    if (elt[key] instanceof Array) {
      elt[key].push(mod);
    } else {
      elt[key] = [ elt[key], mod ];
    }
  } else {
    elt[key] = mod;
  }
}

function normalizeSelector(elt, rest) {
  for (var i = 0; i < rest.length; ++i) {
    var mod = rest[i];
    //console.log('normalizeSelector', elt, mod);
    if (mod.class) {
      normalizeHelper(elt, 'class', mod);
    } else if (mod.id) {
      normalizeHelper(elt, 'id', mod);
    } else if (mod.attr) {
      normalizeHelper(elt, 'attr', mod);
    } else if (mod.pseudo) {
      normalizeHelper(elt, 'pseudo', mod);
    }
  }
  return elt;
} 

function normalizeSelectorRelation(elt, rel, relElt) {
  elt[rel] = relElt;
  return elt;
}

function keyvalsToObject (keyvals) {
  var result = {};
  for (var i in keyvals) {
    result[keyvals[i][0]] = keyvals[i][1];
  }
  return result;
}

var depthCount = 0; 
var maxDepthCount = 200;

function normalizeChainedSelector(elt, rest) {
  var top = elt;
  for (var i = 0; i < rest.length; ++i) {
    var item = rest[i];
    var rel = 'ancestor';
    var elt = null;
    if (item.child) {
      rel = 'parent';
      elt = item.child;
    } else if (item.immediatePrecede) {
      rel = 'immediatePrecede';
      elt = item.immediatePrecede;
    } else if (item.precede) {
      rel = 'precede';
      elt = item.precede;
    } else {
      elt = item.descend;
    }
    top = normalizeSelectorRelation(elt, rel, top);
  }
  return top;
}

}

/**********************************************************************
START
**********************************************************************/

START
  = _ head:Statement rest:Statement*_ { 
    if (rest.length == 0) {
      return head; 
    } else {
      return [ head ].concat(rest);
    }
  }

/**********************************************************************
Statement
**********************************************************************/
Statement
  = exp:SelectorExpression _ { return {select: exp}; }

/**********************************************************************
CSS Selector

http://www.w3.org/TR/css3-selectors/

**********************************************************************/

SelectorExpression
  = GroupSelectorExp
  / ChainedSelector

/**********************************************************************
  these are single selector and its modifiers... 
**********************************************************************/
SingleSelectorExp
  = elt:ElementSelectorExp mods:SelectorModifierExp* {
    return normalizeSelector(elt, mods); 
  }
  / mod:SelectorModifierExp {
    return normalizeSelector({elt: '*'}, [ mod ]);
  }

ElementSelectorExp
  = elt:Identifier { return {elt: elt}; }
  / '*' { return {elt: '*'}; }
  / exp:ClassSelectorExp { return normalizeSelector({elt: '*'}, [ exp ]); }
  / exp:IDSelectorExp { return normalizeSelector({elt: '*'}, [ exp ]); }
  / exp:AttributeSelectorExp { return normalizeSelector({elt: '*'}, [ exp ]); }

SelectorModifierExp
  = ClassSelectorExp
  / IDSelectorExp
  / AttributeSelectorExp
  / PseudoElementSelectorExp

ClassSelectorExp
  = '.' cls:Identifier { return {class: cls}; }

IDSelectorExp
  = '#' id:Identifier { return {id: id}; }

AttributeSelectorExp
  = '[' _ attr:Identifier _ ']' _ { return { attr: attr }; }
  / '[' _ attr:Identifier _ op:('=' / '~=' / '^=' / '$=' / '*=' / '|=' / '!=') _ val:Literal _ ']' _
  { 
    return { attr: attr, op: op, arg: val};
  }

PseudoElementSelectorExp
  = ':' _ 'not' _ '(' arg:SelectorModifierExp ')' {
    return { pseudo: 'not', args: [ arg ]}
  }
  / ':' name:Identifier '(' arg:Literal ')' { 
    return { pseudo: name, args: [ arg ] };
  }
  / ':' name:Identifier { 
    return { pseudo: name };
  }

/**********************************************************************
compound selectors and modifiers
**********************************************************************/

ChainedSelector 
= first:SingleSelectorExp _ items:chainedSelectorItem* {
  return normalizeChainedSelector(first, items);
}

chainedSelectorItem
= childSelector
/ descedentSelector
/ immediatePrecedeSelector
/ precedeSelector

childSelector
= '>' _ s:SingleSelectorExp _ {
  return {child: s};
}

descedentSelector
= s:SingleSelectorExp _ {
  return {descend: s};
}

immediatePrecedeSelector
= '+' _ s:SingleSelectorExp _ {
  return {immediatePrecede: s};
}

precedeSelector
= '~' _ s:SingleSelectorExp _ {
  return {precede: s};
}

/**********************************************************************
group selectors
**********************************************************************/


GroupSelectorExp
  = head:ChainedSelector _ rest:_tailGroupSelectorExp* _ { return [ head ].concat(rest); }

_tailGroupSelectorExp
  = ',' _ exp:ChainedSelector _ { return exp; }

/**********************************************************************
Atomic Expression

literals (string, number, boolean, null), references, etc.

**********************************************************************/

Identifier
  = !Keywords head:idChar1 rest:idChar* { return makeString(head, rest); }

idChar1
  = [a-z]
  / [A-Z]
  / '_'

idChar
  = [a-z]
  / [A-Z]
  / '-'
  / '_'
  / [0-9]

Keywords
  = 'if'
  / 'else'
  / 'try'
  / 'catch'
  / 'throw'
  / 'finally'
  / 'function'


Literal
  = String
  / Number
  / 'true' { return true; }
  / 'false' { return false; }
  / 'null' { return null; }


/**********************************************************************
  Lexical Elements
**********************************************************************/

String
  = '"' chars:doubleQuoteChar* '"' _ { return chars.join(''); }
  / "'" chars:singleQuoteChar* "'" _ { return chars.join(''); }

singleQuoteChar
  = '"'
  / char

doubleQuoteChar
  = "'"
  / char

char // In the original JSON grammar: "any-Unicode-character-except-"-or-\-or-control-character"
  = [^"'\\\0-\x1F\x7f]
  / '\\"'  { return '"';  }
  / "\\'"  { return "'"; }
  / "\\\\" { return "\\"; }
  / "\\/"  { return "/";  }
  / "\\b"  { return "\b"; }
  / "\\f"  { return "\f"; }
  / "\\n"  { return "\n"; }
  / "\\r"  { return "\r"; }
  / "\\t"  { return "\t"; }
  / whitespace 
  / "\\u" digits:hexDigit4 {
      return String.fromCharCode(parseInt("0x" + digits));
    }

hexDigit4
  = h1:hexDigit h2:hexDigit h3:hexDigit h4:hexDigit { return h1+h2+h3+h4; }

Number
  = int:int frac:frac exp:exp _ { return parseFloat([int,frac,exp].join('')); }
  / int:int frac:frac _     { return parseFloat([int,frac].join('')); }
  / int:int exp:exp _      { return parseFloat([int,exp].join('')); }
  / int:int _          { return parseFloat(int); }

int
  = digits:digits { return digits.join(''); }
  / "-" digits:digits { return ['-'].concat(digits).join(''); }

frac
  = "." digits:digits { return ['.'].concat(digits).join(''); }

exp
  = e digits:digits { return ['e'].concat(digits).join(''); }

digits
  = digit+

e
  = [eE] [+-]?

digit
  = [0-9]

digit19
  = [1-9]

hexDigit
  = [0-9a-fA-F]


_ "whitespace"
  = whitespace*

// Whitespace is undefined in the original JSON grammar, so I assume a simple
// conventional definition consistent with ECMA-262, 5th ed.
whitespace
  // = comment
  = [ \t\n\r]


lineTermChar
  = [\n\r\u2028\u2029]

lineTerm "end of line"
  = "\r\n"
  / "\n"
  / "\r"
  / "\u2028" // line separator
  / "\u2029" // paragraph separator

sourceChar
  = .

