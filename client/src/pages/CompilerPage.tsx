import React, { useState, useEffect, useRef } from 'react';
import { Box, AppBar, Toolbar, Typography, Button, Tab, Tabs, Paper } from '@mui/material';
import Editor from '@monaco-editor/react';
import axios from 'axios';
import Terminal from '../components/Terminal';
import { TabPanel } from '../components/TabPanel';
import Navbar from '../components/Navbar';


const CompilerPage: React.FC = () => {
  const [code, setCode] = useState(`#include <stdio.h>\n\nint main() {\n    printf("Hello, World!\\n");\n    return 0;\n}`);
  const [output, setOutput] = useState('');
  const [compiling, setCompiling] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [parseTable, setParseTable] = useState('');
  const [symbolTable, setSymbolTable] = useState('');
  const [constantTable, setConstantTable] = useState('');
  const [editorHeight, setEditorHeight] = useState('60%');
  const [terminalHeight, setTerminalHeight] = useState('35%');
  const [formattedParseTable, setFormattedParseTable] = useState('');
  const [compilationId, setCompilationId] = useState<string | null>(null);

  // Set stable heights on initial load
  useEffect(() => {
    // Use a timeout to ensure the layout has settled
    const timer = setTimeout(() => {
      const containerHeight = window.innerHeight - 64; // Subtract AppBar height
      setEditorHeight(`${Math.floor(containerHeight * 0.6)}px`);
      setTerminalHeight(`${Math.floor(containerHeight * 0.35)}px`);
    }, 300);
    
    return () => clearTimeout(timer);
  }, []);

  // Format the parse table into a tabular structure
  useEffect(() => {
    if (!parseTable) {
      setFormattedParseTable('No lexical analysis data available');
      return;
    }

    try {
      // Create CSS for table layout
      let result = '<style>\n';
      result += ':root {\n';
      result += '  --bg-dark: #121212;\n';
      result += '  --bg-surface: #1e1e1e;\n';
      result += '  --border-color: #333333;\n';
      result += '  --accent-color: #bb86fc;\n';
      result += '  --text-primary: #e0e0e0;\n';
      result += '  --text-secondary: #a0a0a0;\n';
      result += '}\n';
      result += '.parse-table { width: 100%; border-collapse: collapse; font-family: sans-serif; color: var(--text-primary); }\n';
      result += '.parse-table th { padding: 8px; text-align: left; background-color: #2d2d2d; color: var(--accent-color); border: 1px solid var(--border-color); }\n';
      result += '.parse-table tr:nth-child(odd) td { background-color: #242424; }\n';
      result += '.parse-table tr:nth-child(even) td { background-color: #1e1e1e; }\n';
      result += '.parse-table td { padding: 8px; border: 1px solid var(--border-color); vertical-align: top; }\n';
      result += '</style>\n';
      
      // Start table
      result += '<table class="parse-table">\n';
      result += '  <thead>\n';
      result += '    <tr>\n';
      result += '      <th>LEXEME</th>\n';
      result += '      <th>TYPE</th>\n';
      result += '      <th>ATTRIBUTE</th>\n';
      result += '      <th>LINE NUMBER</th>\n';
      result += '    </tr>\n';
      result += '  </thead>\n';
      result += '  <tbody>\n';
      
      // Add table rows
      const lines = parseTable.split('\n').filter(line => line.trim());
      lines.forEach(line => {
        // Skip headers or non-data lines
        if (line.startsWith('lexme') || !line.includes('|')) {
          return;
        }
        
        // Parse the line
        const parts = line.split(' | ');
        if (parts.length >= 4) {
          const lexeme = parts[0].trim();
          const type = parts[1].trim();
          const attribute = parts[2].trim();
          const lineNo = parts[3].trim();
          
          result += '    <tr>\n';
          result += `      <td>${escapeHtml(lexeme)}</td>\n`;
          result += `      <td>${escapeHtml(type)}</td>\n`;
          result += `      <td>${escapeHtml(attribute)}</td>\n`;
          result += `      <td>${escapeHtml(lineNo)}</td>\n`;
          result += '    </tr>\n';
        }
      });
      
      // End table
      result += '  </tbody>\n';
      result += '</table>';
      
      setFormattedParseTable(result);
    } catch (error) {
      console.error('Error formatting parse table:', error);
      setFormattedParseTable(`<pre>${parseTable}</pre>`);
    }
  }, [parseTable]);

  // Helper function to escape HTML special characters
  const escapeHtml = (unsafe: string) => {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  };

  const handleEditorChange = (value: string | undefined) => {
    if (value !== undefined) {
      setCode(value);
    }
  };

  const handleCompile = async () => {
    setCompiling(true);
    setOutput('Compiling...');
    
    try {
      const response = await axios.post('http://localhost:5000/api/compile', { code });
      setCompilationId(response.data.compilationId || null);
      setOutput(response.data.output + (response.data.error ? '\n' + response.data.error : ''));
      setParseTable(response.data.parseTable || 'No parse table data available');
      setSymbolTable(response.data.symbolTable || 'No symbol table data available');
      setConstantTable(response.data.constantTable || 'No constant table data available');
    } catch (error) {
      console.error('Compilation error:', error);
      setOutput('Error: Failed to communicate with the server.');
    } finally {
      setCompiling(false);
      setCompilationId(null);
    }
  };

  const handleTerminateCompilation = async () => {
    if (compilationId) {
      try {
        await axios.post('http://localhost:5000/api/terminate', { compilationId });
        setOutput(prev => prev + '\n\nCompilation terminated by user.');
      } catch (error) {
        console.error('Error terminating compilation:', error);
        setOutput(prev => prev + '\n\nFailed to terminate compilation.');
      } finally {
        setCompiling(false);
        setCompilationId(null);
      }
    }
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleSendInput = (input: string) => {
    // This is a placeholder for sending input to the running process
    axios.post('http://localhost:5000/api/input', { input })
      .catch(error => console.error('Error sending input:', error));
  };

  const handleTitleClick = () => {
    window.location.reload();
  };

  return (
    <Box sx={{ flexGrow: 1, height: '100vh', display: 'flex', flexDirection: 'column', overflow: 'hidden', bgcolor: '#121212' }}>
      <Navbar />
      
      <Box sx={{ display: 'flex', flexGrow: 1, overflow: 'hidden', bgcolor: '#121212' }}>
        {/* Left side: Editor + Terminal */}
        <Box sx={{ 
          display: 'flex', 
          flexDirection: 'column', 
          p: 1, 
          width: '50%', 
          flexBasis: '50%',
          flexGrow: 0,
          flexShrink: 0,
          overflow: 'hidden' 
        }}>
          <Paper 
            elevation={3} 
            sx={{ 
              mb: 1, 
              p: 1, 
              position: 'relative', 
              height: editorHeight,
              display: 'flex',
              flexDirection: 'column',
              bgcolor: '#1e1e1e',
              borderRadius: 1
            }}
          >
            <Editor
              height="100%"
              defaultLanguage="c"
              value={code}
              onChange={handleEditorChange}
              options={{
                minimap: { enabled: false },
                lineNumbers: 'on',
                scrollBeyondLastLine: false,
                fontSize: 14,
                automaticLayout: true, // Important for resize handling
                theme: 'vs-dark'
              }}
            />
            <Box sx={{ position: 'absolute', top: 8, right: 8, display: 'flex', gap: 2 }}>
              {compiling ? (
                <Button 
                  variant="contained" 
                  color="error"
                  onClick={handleTerminateCompilation}
                  sx={{ borderRadius: 1, textTransform: 'none' }}
                >
                  Terminate
                </Button>
              ) : (
                <Button 
                  variant="contained" 
                  color="primary"
                  onClick={handleCompile}
                  sx={{ borderRadius: 1, textTransform: 'none' }}
                >
                  Compile & Run
                </Button>
              )}
            </Box>
          </Paper>
          
          <Paper 
            elevation={3} 
            sx={{ 
              height: terminalHeight,
              overflow: 'hidden',
              bgcolor: '#1e1e1e',
              borderRadius: 1
            }}
          >
            <Terminal 
              output={output} 
              onSendInput={handleSendInput}
            />
          </Paper>
        </Box>
        
        {/* Right side: Phases Panel */}
        <Box sx={{ 
          width: '50%', 
          flexBasis: '50%',
          flexGrow: 0,
          flexShrink: 0,
          p: 1, 
          overflow: 'hidden' 
        }}>
          <Paper elevation={3} sx={{ height: '100%', overflow: 'hidden', bgcolor: '#1e1e1e', borderRadius: 1 }}>
            <Box sx={{ borderBottom: 1, borderColor: 'rgba(255,255,255,0.1)', bgcolor: '#252525' }}>
              <Tabs 
                value={tabValue} 
                onChange={handleTabChange} 
                centered
                sx={{
                  '& .MuiTab-root': { color: '#e0e0e0' },
                  '& .Mui-selected': { color: '#bb86fc', fontWeight: 'bold' },
                  '& .MuiTabs-indicator': { backgroundColor: '#bb86fc' }
                }}
              >
                <Tab label="Lexical Phase" />
                <Tab label="Syntax Phase" />
                <Tab label="Semantic Phase" />
              </Tabs>
            </Box>
            
            <TabPanel value={tabValue} index={0}>
              <Box 
                sx={{ 
                  p: 2, 
                  overflow: 'auto', 
                  height: 'calc(100vh - 180px)',
                  bgcolor: '#1e1e1e',
                  color: '#e0e0e0'
                }}
                dangerouslySetInnerHTML={{ __html: formattedParseTable }}
              />
            </TabPanel>
            
            <TabPanel value={tabValue} index={1}>
              <Box component="pre" sx={{ p: 2, overflow: 'auto', height: 'calc(100vh - 180px)', bgcolor: '#1e1e1e', color: '#e0e0e0' }}>
                {/* Placeholder for Syntax Phase */}
                Syntax Phase Placeholder
              </Box>
            </TabPanel>
            
            <TabPanel value={tabValue} index={2}>
              <Box component="pre" sx={{ p: 2, overflow: 'auto', height: 'calc(100vh - 180px)', bgcolor: '#1e1e1e', color: '#e0e0e0' }}>
                <Typography variant="h6" sx={{ color: '#bb86fc' }}>Symbol Table:</Typography>
                {symbolTable}
                <Typography variant="h6" sx={{ mt: 2, color: '#bb86fc' }}>Constant Table:</Typography>
                {constantTable}
              </Box>
            </TabPanel>
          </Paper>
        </Box>
      </Box>
    </Box>
  );
};

export default CompilerPage; 