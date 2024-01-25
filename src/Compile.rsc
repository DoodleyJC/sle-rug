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
  //println(bodyList);
  //println(li(bodyList));
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
      return getHTMLElementComputedQuestion(name, id, questionType);
    }
    
    default:
    ;
  }
  return li([]);
}


HTMLElement getHTMLElementComputedQuestion(str name, AIdent id, AType questionType){
  HTMLElement res = li([text(name+" (computed)")]);
  res.id = id.name;
  return res;
  }

HTMLElement getHTMLElementQuestion(str name, AIdent id, AType questionType){
  HTMLElement htmlQuestion = input();
  htmlQuestion.id = id.name;
  switch(questionType.name){
    case "boolean":{
      htmlQuestion.\type = "checkbox";
      htmlQuestion.oninput = "updateValue(this.id, this.checked); updateAll(); ";
    }
    case "integer": {
      htmlQuestion.\type = "number";
      htmlQuestion.oninput = "updateValue(this.id, this.value); updateAll();";
    }
  }
  return li([text(name),htmlQuestion]);
}



HTMLElement ifQuestionHTML(AExpr cond, list[AQuestion] thenBlock){
  HTMLElement res = ol(([] | it + compileQuestionHTML(inner) | inner <- thenBlock));
  res.id = "if<cond.src.offset>";
  res.style = "visibility: inherit";
  return res;
}

HTMLElement ifElseQuestionHTML(AExpr cond, list[AQuestion] thenBlock, list[AQuestion] elseBlock){
  HTMLElement ifpart = ol(([] | it + compileQuestionHTML(inner) | inner <- thenBlock));
  ifpart.id = "if<cond.src.offset>";
  ifpart.style = "visibility: hidden";
  HTMLElement elsepart = ol(([] | it + compileQuestionHTML(inner) | inner <- elseBlock));
  elsepart.id = "else<cond.src.offset>";
  elsepart.style = "visibility: hidden";
  return div([ifpart, elsepart]);
}


str form2js(AForm f) {
  str result = "";
  result += readFile(|project://sle-rug/src/test.js|);
  visit(f){
    case form(_, list[AQuestion] listQuestions):
      {
        result+= ("" | it + question2js(q) | q<- listQuestions);
      }
  }
  return result;
}

str question2js(AQuestion q){
  println("called");
  str result = "";
  switch(q){
    case ifQuestion(AExpr cond, list[AQuestion] thenBlock):
      {
        identhelp = "if" + thenBlock[0].ident.name;
        identhelp = "if<cond.src.offset>";
        result+= "function update<identhelp>(){
                var element = document.getElementById(\"<identhelp>\");
                if(<expressionToJs(cond)> == undefined){
                  return;
                }
                if(<expressionToJs(cond)>){
                    changeChildrenVisibility(element, \"visible\");
                } else{
                    changeChildrenVisibility(element, \"hidden\");
                }
            }
            functionTable.push(update<identhelp>);";
        println("test1");
        //println(thenBlock);
        result += ("" | it + question2js(que) | que <- thenBlock);
        println("test2");
        return result;
      } 
    case question(str name, AIdent id, _, AExpr exp):{
      return "
function updateComp<id.name>(){
  var element = document.getElementById(\"<id.name>\");
  element.textContent = <name> + String(<expressionToJs(exp)>);
  symbolTable.set(\"<id.name>\", <expressionToJs(exp)>);
}
functionTable.push(updateComp<id.name>);"
      ;
    }

    case ifElseQuestion(AExpr cond, list[AQuestion] thenBlock, list[AQuestion] elseBlock): {
      result ="";
      identif = "if<cond.src.offset>";
      identelse = "else<cond.src.offset>";
result +=    
"function ifelse<cond.src.offset>(){
    var elementif = document.getElementById(\"<identif>\");
    var elementelse = document.getElementById(\"<identelse>\");
    if(<expressionToJs(cond)> == undefined){
                  return;
                }
    if(<expressionToJs(cond)>){
        changeChildrenVisibility(elementif, \"visible\");
        changeChildrenVisibility(elementelse, \"hidden\");

    } else{
        changeChildrenVisibility(elementif, \"hidden\");
        changeChildrenVisibility(elementelse, \"visible\");
    }
}
functionTable.push(ifelse<cond.src.offset>);";
      println("test3");
      result += ("" | it + question2js(ques) | ques<-thenBlock);
      result += ("" | it + question2js(ques) | ques<- elseBlock);
      println("test4");
      return result;
    }
    default: {
      println("error");
      return "";
    }
  }
}



str expressionToJs(AExpr e){
  println("exptojs called");
  switch(e){
    case ref(AIdent id):{
      return "symbolTable.get(\"<id.name>\")";
    }
    case inte(int n):{
      return "Number(<n>)";
    }
    case boo(bool b):{
      return "<b>";
    }
    case unary(AExpr exp):{
      return "!(<expressionToJs(exp)>)";
    }
    case binary(AExpr lhs, str op, AExpr rhs):{
      return "Number(<expressionToJs(lhs)>) <op> Number(<expressionToJs(rhs)>)";
    }


    default: 
      return "error";
  }
}

