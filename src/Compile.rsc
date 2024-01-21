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
  //writeFile(f.src[extension="js"].top, form2js(f)); //dont you dare forget to uncomment this
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

void compileTest(){
  writeFile(|project://sle-rug/HTMLoutput/test|[extension="html"].top, writeHTMLString(testhtml()));
}

HTMLElement form2html(AForm f) {
  HTMLhead = head([]);
  bodyList = [];
  visit(f){
    case form(_, list[AQuestion] listQuestions):
    {
      bodyList += ([] | it + testHTMLQuestion(que) | que <- listQuestions);
    }
  }
  println(bodyList);
  return html([head([]), body(bodyList)]);
}

HTMLElement testhtml(){
  HTMLElement input1 = input();
  input1.label = "test";
  input1.\type = "checkbox";
  return html([head([]), body([input1])]);
}


list[HTMLElement] testHTMLQuestion(AQuestion q){
  bodyList = [];
  visit(q){
    case question(str name, AIdent id, _):
    {
      bodyList += h1([text(name)]);
      HTMLElement htmlQuestion = input();
      htmlQuestion.label = "cute";
      htmlQuestion.id = id.name;
      htmlQuestion.\type = "checkbox";
      bodyList += htmlQuestion;
      println("HELLOOOOO");
    }
    case question(str name, AIdent id, _, _):
    {
      bodyList += h1([text(name)]);
      HTMLElement htmlQuestion = input();
      htmlQuestion.label = "cute";
      htmlQuestion.id = id.name;
      htmlQuestion.\type = "checkbox";
      bodyList += htmlQuestion;
      println( "HELLOOOOOOOO");
    }
    default:
    ;
  }
  println(bodyList);
  return bodyList;
}


str form2js(AForm f) {
  return "";
}
