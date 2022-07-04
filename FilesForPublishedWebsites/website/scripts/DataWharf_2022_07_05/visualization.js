function createGraph(container, nodes, edges, autoLayout, rerouteEdgesOnVertexMove, edgeLayout, resetEdges) {
    var model = new mxGraphModel();
    var graph = new mxGraph(container, model);
    graph.setHtmlLabels(true);
    graph.setAllowDanglingEdges(false);
    graph.setDisconnectOnMove(false);
    graph.setTooltips(true);
    graph.autoExtend = true;
    graph.autoScroll = true;
    graph.allowNegativeCoordinates = false;

    new mxRubberband(graph);

    graph.isCellEditable = function(cell) {
        return cell.id.startsWith("D") || cell.id.startsWith("L");
    };
    graph.getTooltipForCell = function(cell) {
        return cell.tooltip;
    };

    graph.getSelectionModel().setSingleSelection(false);

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
                if(edgeLayout == "orthogonal") {
                    style[mxConstants.STYLE_EDGE] = mxEdgeStyle.OrthConnector;
                    //style[mxConstants.STYLE_EDGE] = mxEdgeStyle.SegmentConnector;
                    //style[mxConstants.STYLE_EDGE] = mxEdgeStyle.ElbowConnector;
                } else {
                    //default is direct
                }

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
            var width = node.width > 0 ?  node.width : 100;
            var height = node.height > 0 ?  node.height : 50;
            if(node.id.startsWith('A')) {
                //association shape is always the same size
                width = 50;
                height = 50;
                nodeStyle += 'verticalLabelPosition=bottom;verticalAlign=top;';
            }
            var mxNode = graph.insertVertex(parent, node.id, node.label, node.x, node.y, width, height, nodeStyle);
            mxNode.highlight = node.color.highlight;
            mxNode.color = node.color;
            mxNode.color.border = '#000000';
            mxNodes.set(node.id, mxNode);
            if(!node.id.startsWith('A')) {
                //adapt size to fit content if content is longer (except for association shape)
                var preferred = graph.getPreferredSizeForCell(mxNode);
                var current = mxNode.getGeometry();
                current.width = preferred.width > width ? preferred.width : width;
                current.height = preferred.height > height ? preferred.height : height;
            }
            mxNode.tooltip = node.title;
            //ensure in size

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
            style += "strokeColor="+edge.color.color+";";
            var mxEdge = graph.insertEdge(parent, edge.id, edge.label, mxNodes.get(edge.from), mxNodes.get(edge.to),style);
            mxEdge.highlight = edge.color.highlight;
            mxEdge.color = edge.color.color;
            if(edge.points) {
                mxEdge.geometry.points = edge.points;
            }
            
            var endLabel1 = graph.insertVertex(mxEdge, null, edge.labelFrom, -0.75, -20, 1, 1,
    						'fillColor=none;strokeColor=none;rounded=1;arcSize=25;strokeWidth=3;fontStyle=0', true);
            graph.updateCellSize(endLabel1);
            // Adds padding (labelPadding not working...)
            endLabel1.geometry.width = 16;
            endLabel1.geometry.height = 12;
            var endLabel2 = graph.insertVertex(mxEdge, null, edge.labelTo, 0.75, 20, 1, 1,
                'fillColor=none;strokeColor=none;rounded=1;arcSize=25;strokeWidth=3;fontStyle=0', true);
            graph.updateCellSize(endLabel2);
            // Adds padding (labelPadding not working...)
            endLabel2.geometry.width = 16;
            endLabel2.geometry.height = 12;
            mxEdge.geometry.offset = new this.mxPoint(0, -5);
            mxEdge.tooltip = edge.title;
            mxEdges.set(edge.id, mxEdge);
        });
    }
    finally
    {
        // Updates the display
        model.endUpdate();
    }

    if(rerouteEdgesOnVertexMove) {
        graph.addListener(mxEvent.CELLS_MOVED, function (sender, evt) {
            var cells = evt.getProperties("cell");
            if(cells && cells.cells && cells.cells.length > 0 && cells.cells[0].isVertex()) {
                rerouteEdges(graph, cells.cells[0]);
            }
        });
    }

    if(autoLayout) {
        var layout = new mxFastOrganicLayout(graph);
        layout.disableEdgeStyle = false;
        layout.execute(graph.getDefaultParent());
        /*var layoutEdges = new mxParallelEdgeLayout(graph);
        layoutEdges.execute(graph.getDefaultParent());*/
    }

    if(resetEdges) {
        new mxParallelEdgeLayout(graph).execute(graph.getDefaultParent());
    }

    var zoomIn = container.parentElement.appendChild(mxUtils.button(' Zoom In ', function(event)
    {
        event.preventDefault();
        graph.zoomIn();
    }));
    $(zoomIn).addClass("btn btn-primary rounded ms-3").prepend("<i class='bi bi-zoom-in'></i>");

    var fit = container.parentElement.appendChild(mxUtils.button(' Fit ', function(event)
    {
        event.preventDefault();
        graph.fit();
    }));
    $(fit).addClass("btn btn-primary rounded ms-3").prepend("<i class='bi bi-arrows-fullscreen'></i>");
    
    var zoomOut = container.parentElement.appendChild(mxUtils.button(' Zoom Out ', function(event)
    {
        event.preventDefault();
        graph.zoomOut();
    }));
    $(zoomOut).addClass("btn btn-primary rounded ms-3").prepend("<i class='bi bi-zoom-out'></i>");

    var reroute = container.parentElement.appendChild(mxUtils.button(' Reroute Edges ', function(event)
    {
        event.preventDefault();
        var cells = graph.getSelectionCells();
        if(cells && cells.length > 0)
        {
            cells.forEach(cell => {
                rerouteEdges(graph, cell);
            });
        }
        else {
            for(var cellProp in graph.model.cells) {
                var cell = graph.model.cells[cellProp];
                if(cell.id.startsWith("L") || cell.id.startsWith("D")) 
                {
                    graph.resetEdge(cell);
                }
                new mxParallelEdgeLayout(graph).execute(graph.getDefaultParent());
            }
        }
        
    }));
    $(reroute).addClass("btn btn-primary rounded ms-3").prepend("<i class='bi bi-bezier2'></i>");


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

function rerouteEdges(graph, cell) {
    var layout = new mxParallelEdgeLayout(graph);
    if (cell.id.startsWith("L") || cell.id.startsWith("D" || cell.id.startsWith("C"))) {
        graph.resetEdge(cell);
        layout.isEdgeIgnored = function (edge2) {
            return !(cell == edge2);
        };
    } else if (cell.id.startsWith("E") || cell.id.startsWith("A") || cell.id.startsWith("T")) {
        graph.resetEdges([cell]);
        layout.isEdgeIgnored = function (edge2) {
            var model = graph.getModel();
            var src2 = model.getTerminal(edge2, true);
            var trg2 = model.getTerminal(edge2, false);

            return !(cell == src2 || cell == trg2);
        };
    }
    layout.execute(graph.getDefaultParent());
}

function getPositions(graph) {
    var positions = {};
    for(var cellProp in graph.model.cells) {
        var cell = graph.model.cells[cellProp];
        if(cell.id.startsWith('E') || cell.id.startsWith('A') || cell.id.startsWith('T')) {
            positions[cell.id] = { id: cell.id, x: cell.geometry.x ,y: cell.geometry.y, height: cell.geometry.height, width: cell.geometry.width}
        } else if (cell.id.startsWith('D') || cell.id.startsWith('L') || cell.id.startsWith('C')) {
            positions[cell.id] = { id: cell.id, points: cell.geometry.points};
        }
    }
    return positions;
}

function SelectGraphCell(cellsAdded, cellsRemoved, graph) {

    graph.getModel().beginUpdate(); // required if you want to apply the highlight to all cells in a single transaction
    try {
        if(cellsAdded) {
            cellsAdded.forEach(element => {
                if(element.highlight && element.highlight.background) {
                    mxUtils.setCellStyles(graph.getModel(), [element], 'fillColor', element.highlight.background);
                }
                if(element.highlight && element.highlight.border) {
                    mxUtils.setCellStyles(graph.getModel(), [element], 'strokeColor', element.highlight.border);
                }
                if(element.edges) {
                    element.edges.forEach(edge => {
                        mxUtils.setCellStyles(graph.getModel(), [edge], 'strokeWidth', 2);
                        mxUtils.setCellStyles(graph.getModel(), [edge], 'strokeColor', edge.highlight);
                    });
                }
            });
        }
        if(cellsRemoved) {
            cellsRemoved.forEach(element => {
                if(element.color && element.color.background) {
                    mxUtils.setCellStyles(graph.getModel(), [element], 'fillColor', element.color.background);
                }
                if(element.color && element.color.border) {
                    mxUtils.setCellStyles(graph.getModel(), [element], 'strokeColor', element.color.border);
                }
                if(element.edges) {
                    element.edges.forEach(edge => {
                        mxUtils.setCellStyles(graph.getModel(), [edge], 'strokeWidth', 1);
                        mxUtils.setCellStyles(graph.getModel(), [edge], 'strokeColor', edge.color);
                    });
                }
            });
        }

    } finally {
        // Updates the display
        graph.getModel().endUpdate();
    }
}