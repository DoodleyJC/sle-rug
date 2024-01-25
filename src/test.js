const symbolTable = new Map();
const functionTable = [];


function hideById(id){
    document.getElementById(id).style.visiblity = "hidden";
}

function showById(id){
    document.getElementById(id).style.visiblity = "visible";
}

function changeChildrenVisibility(element, status){
    if(element.style){
        element.style.visibility = status;
        console.log(element);
    }
    if(status="visible"){
        return;
    }
    for(let child of element.childNodes){
        changeChildrenVisibility(child, status);
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
    for(let f of functionTable){
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
        elementelse.style.visiblity = "visible";
        elementif.style.visibility = "hidden";
    }
}
*/