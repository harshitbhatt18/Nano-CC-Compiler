import React, { useState, useEffect } from 'react';
import { Box, Typography, Button, Tab, Tabs, Paper, Modal, IconButton } from '@mui/material';
import Editor from '@monaco-editor/react';
import axios from 'axios';
import Terminal from '../components/Terminal';
import { TabPanel } from '../components/TabPanel';
import Navbar from '../components/Navbar';
import CloseIcon from '@mui/icons-material/Close';

const CompilerPage: React.FC = () => {
  const [code, setCode] = useState(`#include <stdio.h>\n\nint main() {\n    printf("Welcome to Nano CC Compiler"); \n    return 0;\n}`);
  const [output, setOutput] = useState('');
  const [compiling, setCompiling] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [parseTable, setParseTable] = useState('');
  const [symbolTable, setSymbolTable] = useState('');
  const [constantTable, setConstantTable] = useState('');
  const [editorHeight, setEditorHeight] = useState('60%');
  const [terminalHeight, setTerminalHeight] = useState('35%');
  const [formattedParseTable, setFormattedParseTable] = useState('');
  const [parseTree, setParseTree] = useState('');
  const [showParseTreeModal, setShowParseTreeModal] = useState(false);
  const [formattedSymbolTable, setFormattedSymbolTable] = useState('');
  const [formattedConstantTable, setFormattedConstantTable] = useState('');

  useEffect(() => {
    const timer = setTimeout(() => {
      const containerHeight = window.innerHeight - 64;
      setEditorHeight(`${Math.floor(containerHeight * 0.6)}px`);
      setTerminalHeight(`${Math.floor(containerHeight * 0.35)}px`);
    }, 300);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (!parseTable) {
      setFormattedParseTable('No lexical analysis data available');
      return;
    }

    try {
      let result = '<style>\n';
      result += '.parse-table { width: 100%; border-collapse: collapse; font-family: sans-serif; }\n';
      result += '.parse-table th { padding: 8px; text-align: left; background-color: #2d2d2d; color:  #bb86fc; }\n';
      result += '.parse-table tr:nth-child(odd) td { background-color: #242424; }\n';
      result += '.parse-table tr:nth-child(even) td { background-color: #1e1e1e; }\n';
      result += '.parse-table td { padding: 8px; vertical-align: top; }\n';
      result += '</style>\n';
      result += '<table class="parse-table">\n';
      result += '  <thead>\n    <tr>\n';
      result += '      <th>LEXEME</th>\n      <th>TYPE</th>\n      <th>ATTRIBUTE</th>\n      <th>LINE NUMBER</th>\n';
      result += '    </tr>\n  </thead>\n<tbody>\n';

      const lines = parseTable.split('\n').filter(line => line.trim());
      lines.forEach(line => {
        const parts = line.split(' | ');
        if (parts.length === 4) {
          const [lexeme, type, attribute, lineNo] = parts.map(p => p.trim());
          result += '    <tr>\n';
          result += `      <td>${escapeHtml(lexeme)}</td>\n`;
          result += `      <td>${escapeHtml(type)}</td>\n`;
          result += `      <td>${escapeHtml(attribute)}</td>\n`;
          result += `      <td>${escapeHtml(lineNo)}</td>\n`;
          result += '    </tr>\n';
        }
      });

      result += '</tbody>\n</table>';
      setFormattedParseTable(result);
    } catch (error) {
      console.error('Error formatting parse table:', error);
      setFormattedParseTable(`<pre>${parseTable}</pre>`);
    }
  }, [parseTable]);

  useEffect(() => {
    if (!symbolTable || symbolTable.startsWith('No symbol table')) {
      setFormattedSymbolTable('No symbol table data available');
      return;
    }
    try {
      let result = '<style>\n';
      result += '.semantic-table { width: 100%; border-collapse: collapse; font-family: sans-serif; }\n';
      result += '.semantic-table th { padding: 8px; text-align: left; background-color: #2d2d2d; color:  #bb86fc; }\n';
      result += '.semantic-table tr:nth-child(odd) td { background-color: #242424; }\n';
      result += '.semantic-table tr:nth-child(even) td { background-color: #1e1e1e; }\n';
      result += '.semantic-table td { padding: 8px; vertical-align: top; }\n';
      result += '</style>\n';
      result += '<table class="semantic-table">\n';
      result += '  <thead>\n    <tr>\n';
      result += '      <th>Lexeme</th>\n      <th>Type</th>\n      <th>Line No</th>\n      <th>Scope</th>\n      <th>Func No</th>\n';
      result += '    </tr>\n  </thead>\n<tbody>\n';
      const lines = symbolTable.split('\n').filter(line => line.trim() && !line.startsWith('Lexeme'));
      lines.forEach(line => {
        const parts = line.split(' | ');
        if (parts.length >= 5) {
          const [lexeme, type, lineNo, scope, funcNo] = parts.map(p => p.trim());
          const formattedLineNo = lineNo.split(/\s+/).join(', ');
          result += '    <tr>\n';
          result += `      <td>${escapeHtml(lexeme)}</td>\n`;
          result += `      <td>${escapeHtml(type)}</td>\n`;
          result += `      <td>${escapeHtml(formattedLineNo)}</td>\n`;
          result += `      <td>${escapeHtml(scope)}</td>\n`;
          result += `      <td>${escapeHtml(funcNo)}</td>\n`;
          result += '    </tr>\n';
        }
      });
      result += '</tbody>\n</table>';
      setFormattedSymbolTable(result);
    } catch (error) {
      setFormattedSymbolTable(`<pre>${symbolTable}</pre>`);
    }
  }, [symbolTable]);

  useEffect(() => {
    if (!constantTable || constantTable.startsWith('No constant table')) {
      setFormattedConstantTable('No constant table data available');
      return;
    }
    try {
      let result = '<style>\n';
      result += '.semantic-table { width: 100%; border-collapse: collapse; font-family: sans-serif; }\n';
      result += '.semantic-table th { padding: 8px; text-align: left; background-color: #2d2d2d; color:  #bb86fc; }\n';
      result += '.semantic-table tr:nth-child(odd) td { background-color: #242424; }\n';
      result += '.semantic-table tr:nth-child(even) td { background-color: #1e1e1e; }\n';
      result += '.semantic-table td { padding: 8px; vertical-align: top; }\n';
      result += '</style>\n';
      result += '<table class="semantic-table">\n';
      result += '  <thead>\n    <tr>\n';
      result += '      <th>Value</th>\n      <th>Line No</th>\n';
      result += '    </tr>\n  </thead>\n<tbody>\n';
      const lines = constantTable.split('\n').filter(line => line.trim() && !line.startsWith('Value'));
      lines.forEach(line => {
        const parts = line.split(' | ');
        if (parts.length >= 2) {
          const [value, lineNo] = parts.map(p => p.trim());
          const formattedLineNo = lineNo.split(/\s+/).join(', ');
          result += '    <tr>\n';
          result += `      <td>${escapeHtml(value)}</td>\n`;
          result += `      <td>${escapeHtml(formattedLineNo)}</td>\n`;
          result += '    </tr>\n';
        }
      });
      result += '</tbody>\n</table>';
      setFormattedConstantTable(result);
    } catch (error) {
      setFormattedConstantTable(`<pre>${constantTable}</pre>`);
    }
  }, [constantTable]);

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
      const { output, error, parseTable, symbolTable, constantTable, parseTree } = response.data;

      let finalOutput = output || '';
      if (error) finalOutput += '\n' + error;

      if (!output && !error) {
        finalOutput += '\n\n⚠️ Compilation terminated due to timeout.';
      }

      setOutput(finalOutput.trim() || 'No output returned.');
      setParseTable(parseTable || 'No parse table data available');
      setSymbolTable(symbolTable || 'No symbol table data available');
      setConstantTable(constantTable || 'No constant table data available');
      setParseTree(parseTree || 'No parse tree data available');
    } catch (error) {
      console.error('Compilation error:', error);
      setOutput('Error: Failed to communicate with the server.');
    } finally {
      setCompiling(false);
    }
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleSendInput = (input: string) => {
    axios.post('http://localhost:5000/api/input', { input })
      .catch(error => console.error('Error sending input:', error));
  };

  return (
    <Box sx={{ flexGrow: 1, height: '100vh', display: 'flex', flexDirection: 'column', overflow: 'hidden', bgcolor: '#121212' }}>
      <Navbar />
      <Box sx={{ display: 'flex', flexGrow: 1, overflow: 'hidden', bgcolor: '#121212' }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', p: 1, width: '50%', overflow: 'hidden' }}>
          <Paper elevation={3} sx={{ mb: 1, p: 1, height: editorHeight, bgcolor: '#1e1e1e', borderRadius: 1, position: 'relative' }}>
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
                automaticLayout: true,
                theme: 'vs-dark'
              }}
            />
            <Box sx={{ position: 'absolute', top: 8, right: 8 }}>
              <Button variant="contained" color="primary" onClick={handleCompile} sx={{ borderRadius: 1 }}>
                Compile & Run
              </Button>
            </Box>
          </Paper>
          <Paper elevation={3} sx={{ height: terminalHeight, overflow: 'hidden', bgcolor: '#1e1e1e', borderRadius: 1 }}>
            <Terminal output={output} onSendInput={handleSendInput} />
          </Paper>
        </Box>

        <Box sx={{ width: '50%', p: 1, overflow: 'hidden' }}>
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
                sx={{ p: 2, overflow: 'auto', height: 'calc(100vh - 180px)', bgcolor: '#1e1e1e', color: '#e0e0e0' }}
                dangerouslySetInnerHTML={{ __html: formattedParseTable }}
              />
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              <Box
                sx={{ p: 2, overflow: 'auto', height: 'calc(100vh - 180px)', bgcolor: '#1e1e1e', color: '#e0e0e0', fontFamily: 'monospace', whiteSpace: 'pre', tabSize: 4 }}
                component="pre"
              >
                {parseTree || 'No parse tree data available'}
                <Box sx={{ mt: 3 }}>
                  <Button variant="contained" color="secondary" onClick={() => setShowParseTreeModal(true)}>
                    Show Parse Tree as Image
                  </Button>
                </Box>
              </Box>
              <Modal
                open={showParseTreeModal}
                onClose={() => setShowParseTreeModal(false)}
                sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              >
                <Box sx={{ position: 'relative', width: '100vw', height: '100vh', bgcolor: 'rgba(0,0,0,0.95)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <IconButton onClick={() => setShowParseTreeModal(false)} sx={{ position: 'absolute', top: 16, right: 16, color: '#fff' }}>
                    <CloseIcon fontSize="large" />
                  </IconButton>
                  <img src="http://localhost:5000/api/parsetree-image/parseTree.png" alt="Parse Tree" style={{ maxWidth: '90vw', maxHeight: '90vh', borderRadius: 8 }} />
                </Box>
              </Modal>
            </TabPanel>

            <TabPanel value={tabValue} index={2}>
              <Box sx={{ p: 2, overflow: 'auto', height: 'calc(100vh - 180px)', bgcolor: '#1e1e1e', color: '#e0e0e0' }}>
                <Typography variant="h6" sx={{ color: '#bb86fc' }}>Symbol Table:</Typography>
                <Box dangerouslySetInnerHTML={{ __html: formattedSymbolTable }} />
                <Typography variant="h6" sx={{ mt: 2, color: '#bb86fc' }}>Constant Table:</Typography>
                <Box dangerouslySetInnerHTML={{ __html: formattedConstantTable }} />
              </Box>
            </TabPanel>
          </Paper>
        </Box>
      </Box>
    </Box>
  );
};

export default CompilerPage;
