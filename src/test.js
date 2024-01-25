const symbolTable = new Map();
const functionTable = [];


function hideById(id){
    document.getElementById(id).style.visibility = "hidden";
}

function showById(id){
    document.getElementById(id).style.visibility = "visible";
}
function parentHideSearch(element){
    if(element.parentNode && element.parentNode.style){
        if(element.parentNode.style.visibility == "hidden"){
            return false;
        } else{
            parentHideSearch(element.parentNode);
        }
    }
    return true;
}

function changeChildrenVisibility(element, status){
    
    /*
    if(element.parentNode.style.visibility == "hidden"){
        status = "hidden"
    }
    */

    if(status=="visible" && parentHideSearch(element)){
        if(element.style){
            element.style.visibility = "visible"
        }
        for(let child of element.childNodes){
            if(child.style){
                if(child.parentNode.style.visibility=="hidden"){

                } else{
                    child.style.visibility = "visible";
                }
                
            }
            if(child.tagName == "LI"){

                for(let childchild of child.childNodes){
                    if(childchild.style){
                        childchild.style.visibility = "visible";
                    }
                    
                }
            }
        }  
    }
    if(status=="hidden"){
        if(element.style){
            element.style.visibility = "hidden";
        }
        for(let child of element.childNodes){
            changeChildrenVisibility(child, status);
        }
    }    
}



function updateValue(event){
    if(event.target.type == "checkbox"){
        symbolTable.set(event.target.id, event.target.checked);
    }
    if(event.target.type == "number"){
        symbolTable.set(event.target.id, event.target.value);
    }

    console.log(symbolTable);
}

function updateValue(id, value){
    symbolTable.set(id, value);
    console.log(symbolTable);
}



function updateAll(){
    for(let f of functionTable.reverse()){
        f();
    }
}

/*
function updateCompCheck(){
    var element = document.getElementById("someId");
    element.checked = true;
}

function updateCompText(){
    var element = document.getElementById("something");
    element.textContent = "hahahaha";
}
*/
/* 
function updateIf1(){
    var element = document.getElementById("ifsellingPrice");
    if(symbolTable.get("hasSoldHouse")){
        element.style.visibility = "visible";
        console.log("testtrue");
        console.log(element);
    } else{
        element.style.visibility = "hidden";
        console.log("testflase");
        console.log(element);
    }
}
functionTable.push(updateIf1);
*/
/*
function updateIfElse1(){
    var elementif = document.getElementById("something");
    var elementelse = document.getElementById("something else");
    if("expressionparse"){
        elementif.style.visibility = "visible";
        elementelse.style.visibility = "hidden";
    } else{
        elementelse.style.visibility = "visible";
        elementif.style.visibility = "hidden";
    }
}
*/