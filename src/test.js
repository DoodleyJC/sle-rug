const symbolTable = new Map();

function hideById(id){
    document.getElementById(id).style.visiblity = "hidden";
}

function showById(id){
    document.getElementById(id).style.visiblity = "visible";
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

function evaluateCondition(){
    
}