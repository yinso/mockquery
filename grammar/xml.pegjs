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
  = exp:XHTMLExpression _ { return exp; }

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
XHTML
**********************************************************************/
XHTMLExpression
  = pi:ProcessingInstruction? __ elt:SingleElementExp __ { return {element: elt.tag, attributes: elt.attributes, children: elt.children}; }
  / pi:ProcessingInstruction? __ start:OpenElementExp children:ChildXHTMLExpression* close:CloseElementExp {
    if (start.tag == close.tag) {
      return { element: start.tag, attributes: start.attributes, children: children };
    } else {
      throw new Error("invalid_xhtml_open_close_tag_unequal: " + start.tag);
    }
  } 

ProcessingInstruction
  = '<?' tag:Identifier __ attributes:AttributeExp* __ '?>' __ {
    return { pi: tag, attributes: keyvalsToObject(attributes) };
  }

OpenElementExp
  = tag:StartElementExp __ attributes:AttributeExp* __ '>' {
    return { tag: tag, attributes: keyvalsToObject(attributes) };
  }

CloseElementExp
  = '</' __ name:Identifier __ '>' { 
    return {tag: name}; 
  }

SingleElementExp
  = tag:StartElementExp __ attributes:AttributeExp* __ '/' __ '>' {
    return { tag: tag, attributes: keyvalsToObject(attributes), children: [] };
  }

StartElementExp
  = '<' name:Identifier { 
    return name; 
  }

AttributeExp
  = name:Identifier __ '=' __ value:String __ {
    return [name, value]; 
  }

ChildXHTMLExpression
  = XHTMLExpression
  / XHTMLContentExpression
 
XHTMLContentExpression
  = chars:XHTMLContentChar+ { 
    return chars.join(''); 
  }

XHTMLContentChar
  = XHTMLComment { return ''; }
  / char:(!StartElementExp !CloseElementExp .) { 
    return char[2]; 
  }

__ 
  = (XHTMLComment / whitespace)*

XHTMLComment
  = '<!--' chars:XHTMLCommentChar* XHTMLCommentClose { 
    return { comment: chars.join('') }; 
  }

XHTMLCommentClose
  = '-->'

XHTMLCommentChar
  = char:(!XHTMLCommentClose .) { 
    return char[1]; 
  }

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

char
  // In the original JSON grammar: "any-Unicode-character-except-"-or-\-or-control-character"
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

/* ===== Whitespace ===== */

_ "whitespace"
  = whitespace*

// Whitespace is undefined in the original JSON grammar, so I assume a simple
// conventional definition consistent with ECMA-262, 5th ed.
whitespace
  = comment
  / [ \t\n\r]


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

// should also deal with comment.
comment
  = multiLineComment
  / singleLineComment

singleLineCommentStart
  = '//' // c style

singleLineComment
  = singleLineCommentStart chars:(!lineTermChar sourceChar)* lineTerm? { 
    return {comment: chars.join('')}; 
  }

multiLineComment
  = '/*' chars:(!'*/' sourceChar)* '*/' { return {comment: chars.join('')}; }
