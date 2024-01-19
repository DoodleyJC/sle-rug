module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str name, AIdent ident, AType typ)  
  | question(str name, AIdent ident, AType typ, AExpr e)
  | ifQuestion(AExpr conditional, list[AQuestion] thenBlock)
  | ifElseQuestion(AExpr conditional, list[AQuestion] thenBlock, list[AQuestion] elseBlock)
  ; 


data AExpr(loc src = |tmp:///|)
  = ref(AIdent id)
  | inte(int n)
  | boo(bool b)
  | unary(AExpr other)
  | binary(AExpr lhs, str op, AExpr rhs)
  ;


data AIdent(loc src = |tmp:///|)
  = id(str name)
  ;

data AType(loc src = |tmp:///|)
  = atype(str name)
  ;