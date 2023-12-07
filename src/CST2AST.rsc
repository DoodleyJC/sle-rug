module CST2AST

import Syntax;
import AST;
import String;
import IO;

import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  Ident name = f.name;
  Question* questions = f.questions;
  return form("<name>", [cst2ast(q) | q <- questions ], src=f.src); 
}

default AQuestion cst2ast(Question q) {
  switch(q) {
    case(Question)`<Str s> <Ident name> : <Type ty>`: return question("<s>", id("<name>", src=name.src), cst2ast(ty), src=q.src) ;
    case(Question)`<Str s> <Ident name> : <Type ty> = <Expr e>`: 
      return question("<s>", id("<name>", src=name.src), cst2ast(ty), cst2ast(e), src=q.src);
    case(Question)`if ( <Expr e>) { <Question* questions1> } else { <Question* questions2> }`:
      return question(cst2ast(e), [cst2ast(qr)| qr <- questions1], [cst2ast(qb)| qb <- questions2], src=q.src);
    case(Question)`if ( <Expr e>) { <Question* questions1> }`:
      return question(cst2ast(e), [cst2ast(qr)| qr <- questions1], src=q.src);
      

    default: throw "Not yet implemented <q>";
  }
  
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Ident x>`: return ref(id("<x>", src=x.src), src=x.src);
    case (Expr)`<Int b>` : return ref(toInt("<b>"), src=b.src);
    case (Expr)`(<Expr ex>)` : return ref(cst2ast(ex), src=e.src);
    case (Expr)`<Expr l> *  <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> / <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> + <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> - <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`! <Expr r>`: return ref(cst2ast(r), src=e.src);
    case (Expr)`<Expr l> || <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> && <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> \< <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> \> <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> \<= <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> \>= <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> == <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    case (Expr)`<Expr l> != <Expr r>`: return ref(cst2ast(l), cst2ast(r), src=e.src);
    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  return atype("<t>", src=t.src);
}
