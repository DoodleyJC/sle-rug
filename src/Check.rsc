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
  } else if(typ == "integer"){
    return tint();
  } else if(typ == "string") {
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
    case question(str label_q, AIdent id, AType qTyp): {
      // Check for same name but different types
      for (<_, str name, _, Type typ> <- tenv) {
        if (name == id.name && transformTypeName(qTyp.name) != typ) {
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
    case question(str label_q, AIdent id, AType qTyp, AExpr expr): {
      // Check for same name but different types
      for (<_, str name, _, Type typ> <- tenv) {
        if (name == id.name && transformTypeName(qTyp.name) != typ) {
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
      if(typeOf(expr, tenv, useDef) != transformTypeName(qTyp.name)) {
        msgs += { error("The Type of the question does not match the type of the expression", id.src) };
      }
      msgs += check(expr, tenv, useDef); // Call semantic check on expression!!!

    }

    case ifQuestion(AExpr expr, list[AQuestion] ifQuestions): {
      msgs += check(expr, tenv, useDef); // Call semantic check on expression!!!
      if (typeOf(expr, tenv, useDef) != tbool()) {
        msgs += { error("Non boolean in conditional statement", expr.src) };
      }

      for(AQuestion q <- ifQuestions) {
        msgs += check(q, tenv, useDef); 
      }
    }

    case ifElseQuestion(AExpr expr, list[AQuestion] ifBody, list[AQuestion] elseBody): {
      msgs += check(expr, tenv, useDef); // Call semantic check on expression!!!
      if (typeOf(expr, tenv, useDef) != tbool()) {
        msgs += { error("Non boolean in conditional statement", expr.src) };
      }

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
    case inte(int n): {
      n;
    }
    case boo(bool b): {
      b;
    }
    case stri(str s): {
      s;
    }
    case binary(AExpr left, str op, AExpr right): {
      Type lhsType = typeOf(left, tenv, useDef);
      Type rhsType = typeOf(right, tenv, useDef);
      msgs += check(left, tenv, useDef);
      msgs += check(right, tenv, useDef);
      if ((op == "+" || op == "-" || op == "*" || op == "/" ||  op == "\<" || op == "\<=" || op == "\>" || op == "\>=") && (lhsType != tint() || rhsType != tint())) {
        msgs += { error("Attempting binary operation on non numeric types", e.src) };
      } else if ((op == "&&" || op == "||") && (lhsType != tbool() || rhsType != tbool())) {
        msgs += { error("Attempting boolean operation on non boolean types", e.src) };
      }
    }
    case unary(AExpr expr): {
      Type exprType = typeOf(expr, tenv, useDef);
      if (exprType != tbool()) {
        msgs += { error("Attemping to negate non boolean", e.src) };
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
    case inte(int _): {
      return tint();
    }
    case boo(bool _): {
      return tbool();
    }
    case stri(str _): {
      return tstr();
    }
    case binary(AExpr left, str op, AExpr right): {
      Type lhsType = typeOf(left, tenv, useDef);
      Type rhsType = typeOf(right, tenv, useDef);

      if (op == "\>" || op == "\>=" || op == "\<" || op == "\<=") {
        return tbool();
      }

      if ((lhsType == tint() && rhsType == tint())) {
        return tint();
      } else if(lhsType == tbool() && rhsType == tbool()) {
        return tbool();
      }
      else {
        return tunknown();
      }

    }
    case unary(AExpr expr): {
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
 
 

