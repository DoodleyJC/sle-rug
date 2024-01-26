module Transform
import ParseTree;
import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return visit(f) {
    case form(name, questions): {
      return form(name, flattenListsOfQuestions(questions, Atrue()));
    }
  }; 
}

list[AQuestion] flattenListsOfQuestions(list[AQuestion] questions, AExpr prevGuard) {
    list[AQuestion] flattened = [];
    for (AQuestion q <- questions) {
      switch(q) {
        case ifQuestion(AExpr conditional, list[AQuestion] ifBody): {
          flattened += flattenListsOfQuestions(ifBody, binary(prevGuard, "&&", conditional));
        }
        case ifElseQuestion(AExpr conditional, list[AQuestion] ifBody, list[AQuestion] elseBody): {
          flattened += flattenListsOfQuestions(ifBody, binary(prevGuard, "&&", conditional));
          flattened += flattenListsOfQuestions(elseBody, binary(prevGuard, "&&", unary(conditional)));
        }
        default: {
          flattened += ifQuestion(prevGuard, [q]);
        }
      }
    }
    return flattened;
}

AExpr Atrue() {
  return boo(true);
}


/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  set[loc] locs = {};
  locs += useOrDef;
  locs += { l | (<loc l, useOrDef> <- useDef) };
  locs += { l | (<useOrDef, loc l> <- useDef) };

  if (locs == {}) {
    return f;
  }
  
  return visit(f) {
      case Ident id => replaceName(id, locs, newName)
  }
}

Ident replaceName(Ident id, set[loc] locations, str newName) {
    if (id.src in locations) {
        return [Ident]newName; //this means parse the string newName as an Ident, you could also call the parse function
    } else {
        return id;
    }
}
 
 
 

