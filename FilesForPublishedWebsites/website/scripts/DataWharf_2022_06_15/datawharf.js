function modifyLeafNodes(nodes){
  for(var i = 0, length = nodes.length; i < length; i++){
    if(!nodes[i].nodes || nodes[i].nodes.length === 0){
      nodes[i].nodes = null;
    }else{
      modifyLeafNodes(nodes[i].nodes);
    }
  }
}

function buildTree(tree, item) {
   if (tree) {
    if (item) { 
        for (var i=0; i<tree.length; i++) { 
            if (String(tree[i].id) === String(item.parentId)) { 
                tree[i].nodes.push(item); 
                break;
            }
            else  { buildTree(tree[i].nodes, item); }
        }
      }
      else { 
        var idx = 0;
        while (idx < tree.length) { 
            if (tree[idx].parentId) { buildTree(tree, tree.splice(idx, 1)[0]) } 
            else { idx++; }
        }
      }
    }
};

function buildDTTree(tree, item) {
   if (tree) {
    if (item) { 
        for (var i=0; i<tree.length; i++) { 
            if (String(tree[i].id) === String(item.parentId)) { 
                tree[i].nodes.push(item); 
                tree[i].icon = "bi bi-code-slash"; 
                break;
            }
            else  { buildDTTree(tree[i].nodes, item); }
        }
      }
      else { 
        var idx = 0;
        while (idx < tree.length) { 
            if (tree[idx].parentId) { buildDTTree(tree, tree.splice(idx, 1)[0]) } 
            else { idx++; }
        }
      }
    }
};

$(document).ready(function () {
    $('#sidebarCollapse').on('click', function () {
        $('#sidebarMenu').toggleClass('active');
    });
});


$(document).ready(function(){
    $('.collapse.bstreeview').on('hidden.bs.collapse', function() {
        if (this.id) {
            localStorage[this.id] = 'true';
        }
    }).on('shown.bs.collapse', function() {
        if (this.id) {
            localStorage[this.id] = 'false';
        }
    }).each(function() {
        if(this.id ){
            if (localStorage[this.id] === 'true' ) {
                $(this).collapse('hide');
            } else {
                $(this).collapse('show');
            }
        }
    })
});