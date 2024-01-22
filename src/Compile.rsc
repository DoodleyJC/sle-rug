module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f)); //dont you dare forget to uncomment this
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  HTMLElement scriptElem = script([]);
  scriptElem.src = f.name + ".js";
  HTMLhead = head([scriptElem]);
  bodyList = [];
  visit(f){
    case form(_, list[AQuestion] listQuestions):
    {
      bodyList += ([] | it + compileQuestionHTML(que) | que <- listQuestions);
    }
  }
  println(bodyList);
  println(li(bodyList));
  return html([HTMLhead, body([ol(bodyList)])]);
}

HTMLElement testhtml(){
  HTMLElement input1 = input();
  input1.label = "test";
  input1.\type = "checkbox";
  return html([head([]), body([input1])]);
}


HTMLElement compileQuestionHTML(AQuestion q){
  result = [];
  innerHTML = [];
switch(q){

    case ifQuestion(_, _):
    {
      innerHTML += text("todo: add if block");
    }
    case ifElseQuestion(AExpr cond, list[AQuestion] thenQuestions, list[AQuestion] elseQuestions):{
      innerHTML += text("todo: add ifelse block");
    }
    case question(str name, AIdent id, _):
    {
      print("question printname: ");
      println(name);
      innerHTML += text(name); 
      HTMLElement htmlQuestion = input();
      htmlQuestion.id = id.name;
      htmlQuestion.\type = "checkbox";
      innerHTML += htmlQuestion;
    }
    case question(str name, AIdent id, _, _):
    {
      print("question w/ exp printname: ");
      println(name);
      innerHTML += text(name); 
      HTMLElement htmlQuestion = input();
      htmlQuestion.id = id.name;
      htmlQuestion.\type = "checkbox";
      innerHTML += htmlQuestion;
    }
    
    default:
    ;
  }
  result += innerHTML;
  return li(result);
}


str form2js(AForm f) {
  return readFile(|project://sle-rug/src/test.js|);
}
