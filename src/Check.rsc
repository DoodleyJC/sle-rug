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

Type checkType(Type typ){
  if(typ == tbool()){
    return tbool();
  } else if(typ == tint()){
    return tint();
  } else if(typ == tstr()) {
    return tstr();
  } else {
    return tunknown();
  }
}

str typeToString(Type typ){
  if(typ == tbool()){
    return "bool";
  } else if(typ == tint()){
    return "int";
  } else if(typ == tstr()) {
    return "str";
  } else {
    return "unknown";
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
  set[Message] msgs = {};

  switch(q) {
    case question(str label_q, AIdent id, AType qType):
    {
      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && transformTypeName(qType.name) != myType) {
          msgs += { error("Questions with same name and different types", id.src) };
        }
      }
      
      set[str] encounteredLabels = {};
      // Check for duplicate labels
      if (label_q in encounteredLabels) {
        msgs += { warning("Duplicate labels detected", id.src) };
      } else {
        encounteredLabels += label_q;
      }

    }
    case question(str label_q, AIdent id, AType qType, AExpr expr):
    {
      // Check for same name but different types
      for (<_, str name, _, Type myType> <- tenv) {
        if (name == id.name && transformTypeName(qType.name) != myType) {
          msgs += { error("Questions with same name and different types", id.src) };
        }
      }

      int labelCnt = 0;

      // Check for duplicate labels
      for (<_, _, str label, _> <- tenv) {
        if (label_q == label) { // Assuming identifier.name is unique
          labelCnt += 1;
        }
      }

      if (labelCnt > 1) {
        msgs += { warning("Duplicate labels", id.src) };
      }

      // Check that type of Expression expre matches with type of Question q
      if(typeOf(expr, tenv, useDef) != transformTypeName(qType.name)) {
        msgs += { error("The Type of the question doe not match the type of the expression", id.src) };
      }
      check(expr, tenv, useDef); // Call semantic check on expression!!!

    }
    // IF statements
    case question(AExpr expr, list[AQuestion] ifQuestions):
    {
      for(AQuestion q <- ifQuestions) {
        msgs += check(q, tenv, useDef); 
      }
    }
    // IF ELSE statements
    case question(AExpr expr, list[AQuestion] ifBody, list[AQuestion] elseBody):
    {
      for(AQuestion q <- ifBody) {
        msgs += check(q, tenv, useDef); 
      }
      for(AQuestion q <- elseBody) {
        msgs += check(q, tenv, useDef);
      }
    }
  }

  return msgs; 
}



// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AIdent x): {
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    }
    case ref(int n): {
      n;
    }
    case ref(bool b): {
      b;
    }
    case ref(AExpr left, str op, AExpr right): {
      Type lhsType = typeOf(left, tenv, useDef);
      Type rhsType = typeOf(right, tenv, useDef);
      println(typeToString(lhsType)); 
      println(typeToString(rhsType));
      if (lhsType != tint() || rhsType != tint()) {
        msgs += { error("Attempting binary operation on non numeric types", e.src) };
      }
    }
  }
  
  return msgs; 
}


Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case ref(int _): {
      return tint();
    }
    case ref(AExpr left, str op, AExpr right): {
      Type lhsType = typeOf(left, tenv, useDef);
      Type rhsType = typeOf(right, tenv, useDef);

      // Check that both sides are of type int or both of type bool, else unknown
      if ((lhsType == tint() && rhsType == tint())) {
        return tint();
      } else if(lhsType == tbool() && rhsType == tbool()) {
        return tbool();
      }
      else {
        return tunknown();
      }

    }
    case ref(AExpr expr): {
      Type exprType = typeOf(expr, tenv, useDef);
      return checkType(exprType);
    }
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
 
 

