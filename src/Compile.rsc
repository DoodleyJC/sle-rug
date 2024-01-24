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
  scriptElem.src = f.src[extension="js"].top.file;
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


HTMLElement compileQuestionHTML(AQuestion q){
  innerHTML = [];
switch(q){

    case ifQuestion(AExpr cond, list[AQuestion] thenBlock):
    {
      return ifQuestionHTML(cond, thenBlock);
    }
    case ifElseQuestion(AExpr cond, list[AQuestion] thenQuestions, list[AQuestion] elseQuestions):{
      return ifElseQuestionHTML(cond, thenQuestions, elseQuestions);
    }
    case question(str name, AIdent id, AType questionType):
    {

      return getHTMLElementQuestion(name, id, questionType);
    }
    case question(str name, AIdent id, AType questionType, _):
    {
      return getHTMLElementQuestion(name, id, questionType);
    }
    
    default:
    ;
  }
  return li([]);
}


HTMLElement getHTMLElementQuestion(str name, AIdent id, AType questionType){
  HTMLElement htmlQuestion = input();
  htmlQuestion.id = id.name;
  switch(questionType.name){
    case "boolean":{
      htmlQuestion.\type = "checkbox";
    }
    case "integer": {
      htmlQuestion.\type = "number";
    }
  }
  htmlQuestion.oninput = "updateValue(event)";
  return li([text(name),htmlQuestion]);
}



HTMLElement ifQuestionHTML(AExpr cond, list[AQuestion] thenBlock){
  return ol(([] | it + compileQuestionHTML(inner) | inner <- thenBlock));
}

HTMLElement ifElseQuestionHTML(AExpr cond, list[AQuestion] thenBlock, list[AQuestion] elseBlock){
  return div([ifQuestionHTML(cond, thenBlock), ifQuestionHTML(cond, elseBlock)]);
}


str form2js(AForm f) {
  return readFile(|project://sle-rug/src/test.js|);
}


