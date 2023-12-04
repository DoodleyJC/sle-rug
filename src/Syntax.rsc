module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Ident name "{" Question* questions "}"
  | "HI"
;
// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
= Str s Ident name [:] Type t "="? Expr?
| Ifthenelse
;

syntax Ifthenelse
= Ifthen Else?
;


syntax Ifthen
= "if" "(" Ident i") {" Question* questions "}"
;



syntax Else
= "else {" Question* questions "}"
;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = a :Ident 
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



