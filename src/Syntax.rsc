module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Ident name "{" Question* questions "}"
;
// TODO: question, computed question, block, if-then-else, if-then
/*
syntax QuestionDepr
= Str s Ident name [:] Type t ([=] Expr e)?
| "if" "(" Expr e")" "{" Question* questions1 "}" ("else" "{" Question* questions2 "}")?
;
*/
syntax Question
= Str s Ident name ":" Type t
| Str s Ident name ":" Type t "=" Expr e
| IfThen
| IfThenElse
;


syntax IfThen
= "if" "(" Expr e ")" "{" Question* questions1 "}"
;

syntax IfThenElse
= IfThen "else" "{" Question* questions1 "}"
;


// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = a :Ident
  | Int b
  | Bool
  | Str
  | [(] Expr e [)]
  >left (left Expr l "*"  Expr r
    | left Expr l "/" Expr r)  
  > left (left Expr l "+" Expr r
    | left Expr l "-" Expr r)
  > right "!" Expr r
  > left Expr l "&&" Expr r
  > left Expr l "||" Expr r
  > non-assoc (non-assoc Expr l "\<" Expr r
    | non-assoc Expr l "\>" Expr r
    | non-assoc Expr l "\<=" Expr r
    | non-assoc Expr l "\>=" Expr r
    | non-assoc Expr l "==" Expr r
    | non-assoc Expr l "!=" Expr r)
  ; 
  
syntax Type 
= "boolean"
| "integer"
| "string"
;

lexical Str 
= [\"][a-zA-Z_\ :0-9?]*[\"]  
;

lexical Int 
  = [0-9]+
;

lexical Ident
= Id \Reserved
;

lexical Bool 
= "true" | "false"
;

keyword Reserved
= "true" | "false" | "if" | "else"
;



