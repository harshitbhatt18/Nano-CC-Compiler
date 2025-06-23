#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function parseTreeToDot(inputFile, outputFile) {
    // Check if input file exists
    if (!fs.existsSync(inputFile)) {
        // console.log(`Warning: Input file '${inputFile}' not found. Creating empty parse tree.`);
        const emptyDotContent = [
            'digraph ParseTree {',
            'node [shape=box, fontname="Arial"];',
            'edge [fontname="Arial"];',
            '  error [label="No parse tree available\\n(Syntax analysis failed or no valid code)"];',
            '}'
        ];
        fs.writeFileSync(outputFile, emptyDotContent.join('\n'));
        return;
    }

    // Read the input file
    const lines = fs.readFileSync(inputFile, 'utf8').split('\n');
    
    // Check if file is empty or has no meaningful content
    const meaningfulLines = lines.filter(line => line.trim().length > 0);
    if (meaningfulLines.length === 0) {
        console.log(`Warning: Input file '${inputFile}' is empty. Creating empty parse tree.`);
        const emptyDotContent = [
            'digraph ParseTree {',
            'node [shape=box, fontname="Arial"];',
            'edge [fontname="Arial"];',
            '  error [label="No parse tree available\\n(Empty or invalid input)"];',
            '}'
        ];
        fs.writeFileSync(outputFile, emptyDotContent.join('\n'));
        return;
    }
    
    // Initialize DOT file
    const dotContent = [
        'digraph ParseTree {', 
        'node [shape=box, fontname="Arial"];',
        'edge [fontname="Arial"];'
    ];
    
    let nodeId = 0;
    const nodeIds = {};  // Maps (level, node_text) to node_id
    const parentStack = [];  // Stack of parent node IDs at each level
    
    for (const line of lines) {
        if (!line.trim()) {
            continue;
        }
            
        // Calculate indentation level
        let level = 0;
        for (let i = 0; i < line.length; i++) {
            if (line[i] === ' ') {
                level += 1;
            } else {
                break;
            }
        }
        level = Math.floor(level / 2);  // Assuming 2 spaces per indentation level
        
        // Extract node text
        const nodeText = line.trim();
        
        // Create new node
        nodeId += 1;
        const nodeLabel = `"${nodeText}"`;
        dotContent.push(`  node${nodeId} [label=${nodeLabel}];`);
        
        // Update parent stack based on level
        while (parentStack.length > level) {
            parentStack.pop();
        }
            
        // Add edge from parent to this node if not at root
        if (parentStack.length > 0 && level > 0) {
            const parentId = parentStack[parentStack.length - 1];
            dotContent.push(`  node${parentId} -> node${nodeId};`);
        }
            
        // Push this node as potential parent for next nodes
        if (parentStack.length <= level) {
            parentStack.push(nodeId);
        } else {
            parentStack[level] = nodeId;
        }
    }
    
    // Close the DOT file
    dotContent.push('}');
    
    // Write to output file
    fs.writeFileSync(outputFile, dotContent.join('\n'));
}

function main() {
    // Check command line arguments
    
    parseTreeToDot("parsetree.txt", "parsetree.dot");
    console.log(`DOT file generated`);
}

// Run the main function if this file is executed directly
if (require.main === module) {
    main();
}

// Export the function for use as a module
module.exports = { parseTreeToDot }; 