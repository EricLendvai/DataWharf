function createGraph(container, nodes, edges, autoLayout) {
    var model = new mxGraphModel();
    var graph = new mxGraph(container, model);
    graph.setHtmlLabels(true);
    graph.setAllowDanglingEdges(false);
    graph.setDisconnectOnMove(false);

    var parent = graph.getDefaultParent();

    var style = graph.getStylesheet().getDefaultVertexStyle();
				style['fillColor'] = '#FFFFFF';
				style['strokeColor'] = '#000000';
				style['fontColor'] = '#000000';
                style['rounded'] = '1';
                style['arcSize'] = '10';
                style['html'] = '1';
				
				style = graph.getStylesheet().getDefaultEdgeStyle();
				style['strokeColor'] = '#000000';
				style['fontColor'] = '#000000';
				style['fontStyle'] = '0';
				style['startSize'] = '8';
				style['endSize'] = '8';
                style[mxConstants.STYLE_ROUNDED] = true;
                style[mxConstants.STYLE_EDGE] = mxEdgeStyle.ElbowConnector;

    // Adds cells to the model in a single step
    model.beginUpdate();
    const mxNodes = new Map();
    const mxEdges = new Map();
    try
    {
        
        nodes.forEach(node => {
            var nodeStyle = 'fillColor=' + node.color.background + ';';
            if(node.shape) {
                nodeStyle += 'shape=' + node.shape + ';';
            }
            var mxNode = graph.insertVertex(parent, node.id, node.label, node.x, node.y, 100, 50, nodeStyle);
            mxNodes.set(node.id, mxNode);
            if(!node.shape) {
                graph.updateCellSize(mxNode,true);
            }
            //ensure in size
            if(mxNode.geometry.width < 100) {
                mxNode.geometry.width = 100;
            }
            if(mxNode.geometry.height < 50) {
                mxNode.geometry.height = 50;
            }
        });
        edges.forEach(edge => {
            var styleFrom = '';
            if(edge.arrows && edge.arrows.from && edge.arrows.from.enabled) {
                styleFrom += 'startArrow='+edge.arrows.from.type+';';
            } else {
                styleFrom += 'startArrow=none;';
            }
            var styleTo = '';
            if(edge.arrows && edge.arrows.to && edge.arrows.to.enabled) {
                styleTo += 'endArrow='+edge.arrows.to.type+';';
            } else {
                styleTo += 'endArrow=none;';
            }
            var style = styleFrom + styleTo + 'startFill=1;endFill=1;';
            var mxEdge = graph.insertEdge(parent, edge.id, edge.label, mxNodes.get(edge.from), mxNodes.get(edge.to),style);
            var endLabel1 = graph.insertVertex(mxEdge, null, edge.labelFrom, -0.75, 0, 1, 1,
    						'fillColor=none;strokeColor=none;rounded=1;arcSize=25;strokeWidth=3;fontStyle=0', true);
            graph.updateCellSize(endLabel1);
            // Adds padding (labelPadding not working...)
            endLabel1.geometry.width = 16;
            endLabel1.geometry.height = 12;
            var endLabel2 = graph.insertVertex(mxEdge, null, edge.labelTo, 0.75, 0, 1, 1,
                'fillColor=none;strokeColor=none;rounded=1;arcSize=25;strokeWidth=3;fontStyle=0', true);
            graph.updateCellSize(endLabel2);
            // Adds padding (labelPadding not working...)
            endLabel2.geometry.width = 16;
            endLabel2.geometry.height = 12;
            mxEdge.geometry.offset = new this.mxPoint(0, -5);
            mxEdges.set(edge.id, mxEdge);
        });
    }
    finally
    {
        // Updates the display
        model.endUpdate();
    }

    if(autoLayout) {
        new mxHierarchicalLayout(graph).execute(graph.getDefaultParent());
    }
	return graph;
    /*var executeLayout = function(change, post)
    {
        graph.getModel().beginUpdate();
        try
        {
            if (change != null)
            {
                change();
            }
            
            layout.execute(graph.getDefaultParent());
        }
        catch (e)
        {
            throw e;
        }
        finally
        {
            // New API for animating graph layout results asynchronously
            var morph = new mxMorphing(graph);
            morph.addListener(mxEvent.DONE, mxUtils.bind(this, function()
            {
                graph.getModel().endUpdate();
                
                if (post != null)
                {
                    post();
                }
            }));
            
            morph.startAnimation();
        }
    };
    executeLayout();*/
}

function getPositions(graph) {
    var positions = {};
    for(var cellProp in graph.model.cells) {
        var cell = graph.model.cells[cellProp];
        if(cell.id.startsWith('E') || cell.id.startsWith('A')) {
            positions[cell.id] = { id: cell.id, x: cell.geometry.x ,y: cell.geometry.y}
        }
    }
    return positions;
}