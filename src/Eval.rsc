module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  

Value uninitValue(str typ) {
    if(typ == "integer") {return vint(0);}
    if(typ == "boolean") {return vbool(false);}
    if(typ == "string") {return vstr("");}
    throw "Unknown";
}


// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  
  visit(f) {
    case question(_, AIdent id, AType typ):
      venv[id.name] = uninitValue(typ.name);
    case question(_, AIdent id, _, AExpr expr):
      venv[id.name] = eval(expr, venv);
  }

  return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  visit(f) {
    case form(_, list[AQuestion] questions): {
      for(AQuestion question <- questions) {
        venv = eval(question, inp, venv);
      }
    }
  }

  return venv; 
}


bool transformValueToBool(Value val) {
    switch (val) {
        case vbool(b): return b;
        default: throw "Expected boolean, got other type";
    }
}

int transformValueToInt(Value val) {
  switch (val) {
    case vint(n): return n;
    default: throw "Expected integer, got other type";
  }
}

str transformValueToString(Value val) {
  switch (val) {
    case vstr(s): return s;
    default: throw "Expected string, got other type";
  }
}



VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch (q) {
    case question(_, AIdent id, _): {
      if (id.name == inp.question) {
        venv[id.name] = inp.\value;
      }
    }
    case question(_, AIdent id, _, AExpr expr): {
      if (id.name == inp.question) {
        venv[id.name] = inp.\value;
      } else {
      venv[id.name] = eval(expr, venv);
      }
    }
    case ifQuestion(AExpr expr, list[AQuestion] ifBody): {
      if(transformValueToBool(eval(expr, venv)) == true) {
        for(AQuestion question <- ifBody) {
          venv = eval(question, inp, venv);
        }
      }
    }
    case ifElseQuestion(AExpr expr, list[AQuestion] ifBody, list[AQuestion] elseBody): {
      if(transformValueToBool(eval(expr, venv)) == true) {
        for(AQuestion question <- ifBody) {
          venv = eval(question, inp, venv);
        }
      } else {
        for(AQuestion question <- elseBody) {
          venv = eval(question, inp, venv);
        }
      }
    }
  }
  return venv;
}

Value eval(AExpr e, VEnv venv) {
   switch (e) {
    case ref(id(str x)): { return venv[x]; }
    case inte(int x): { return vint(x); }
    case boo(bool b) : {return vbool(b); }
    case stri(str s): { return vstr(s); }
    case unary(AExpr lhs): {
      Value left = eval(lhs, venv);
      return evalOperator(left, "!", vbool(false));
    }
    case binary(AExpr lhs, str op, AExpr rhs): {
      Value left = eval(lhs, venv);
      Value right = eval(rhs, venv);
      return evalOperator(left, op, right);
    }
   }
   return vint(0);
}

Value evalOperator(Value left, str operator, Value right) {
  switch (operator) {
    case "+": return vint(transformValueToInt(left) + transformValueToInt(right));
    case "-": return vint(transformValueToInt(left) - transformValueToInt(right));
    case "*": return vint(transformValueToInt(left) * transformValueToInt(right));
    case "/": return vint(transformValueToInt(left) / transformValueToInt(right));
    case "!": return vbool(!transformValueToBool(left));
    case "&&": return vbool(transformValueToBool(left) && transformValueToBool(right));
    case "||": return vbool(transformValueToBool(left) || transformValueToBool(right));
    case "\<": return vbool(transformValueToInt(left) < transformValueToInt(right));
    case "\<=": return vbool(transformValueToInt(left) <= transformValueToInt(right));
    case "\>": return vbool(transformValueToInt(left) > transformValueToInt(right));
    case "\>=": return vbool(transformValueToInt(left) >= transformValueToInt(right));
    case "==": {
      if (left is vint && right is vint) {
        return vbool(transformValueToInt(left) == transformValueToInt(right));
      } else if(left is vbool && right is vbool) {
        return vbool(transformValueToBool(left) == transformValueToBool(right));
      } else if(left is vstr && right is vstr) {
        return vbool(transformValueToString(left) == transformValueToString(right));
      } else {
        throw "ERR: <operator>";
      }
    }
    case "!=": {
      if (left is vint && right is vint) {
        return vbool(transformValueToInt(left) != transformValueToInt(right));
      } else if(left is vbool && right is vbool) {
        return vbool(transformValueToBool(left) != transformValueToBool(right));
      } else if(left is vstr && right is vstr) {
        return vbool(transformValueToString(left) != transformValueToString(right));
      } else {
        throw "ERR: <operator>";
      }
    }

    default: throw "ERR: <operator>";
  }
}


