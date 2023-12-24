module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

Type transformTypeName(str typ){
  if(typ == "boolean"){
    return tbool();
  } else if(typ == "int"){
    return tint();
  } else if(typ == "str") {
    return tstr();
  } else {
    return tunknown();
  }
}
// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv env = {}; 
  visit(f) {
    case question(str label, AIdent id, AType typ, _): {
      env += {<id.src, id.name, label, transformTypeName(typ.name)>}; 
    }
    case question(str label, AIdent id, AType typ):{
      env+= {<id.src, id.name, label, transformTypeName(typ.name)>};
    }
  };
  return env; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] messageSet = {};
  visit(f) {
    case form(_, list[AQuestion] questions):{
      set[set[Message]] wrappedSet = {check(q, tenv, useDef) | q <- questions};
      messageSet += ({} | it + inner | inner <- wrappedSet);
    }
  }
  return messageSet;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  return {error("test", |tmp:///|)}; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    // etc.
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

