import React, { useState, useEffect, useRef } from 'react';
import { Box, Typography, Button, Tab, Tabs, Paper, Modal, IconButton } from '@mui/material';
import Editor from '@monaco-editor/react';
import axios from 'axios';
import Terminal from '../components/Terminal';
import { TabPanel } from '../components/TabPanel';
import Navbar from '../components/Navbar';
import CloseIcon from '@mui/icons-material/Close';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import DragIndicatorIcon from '@mui/icons-material/DragIndicator';

const CompilerPage: React.FC = () => {
  const [code, setCode] = useState(`#include <stdio.h>\n\nint main() {\n    printf("Welcome to Nano CC Compiler"); \n    return 0;\n}`);
  const [output, setOutput] = useState('');
  const [compiling, setCompiling] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [parseTable, setParseTable] = useState('');
  const [symbolTable, setSymbolTable] = useState('');
  const [constantTable, setConstantTable] = useState('');
  const [editorHeight, setEditorHeight] = useState(60); // Percentage
  const [terminalHeight, setTerminalHeight] = useState(35); // Percentage
  const [formattedParseTable, setFormattedParseTable] = useState('');
  const [parseTree, setParseTree] = useState('');
  const [showParseTreeModal, setShowParseTreeModal] = useState(false);
  const [formattedSymbolTable, setFormattedSymbolTable] = useState('');
  const [formattedConstantTable, setFormattedConstantTable] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging || !containerRef.current) return;
      
      const containerRect = containerRef.current.getBoundingClientRect();
      const relativeY = e.clientY - containerRect.top;
      const containerHeight = containerRect.height;
      const newEditorPercentage = Math.min(Math.max((relativeY / containerHeight) * 100, 20), 75);
      const newTerminalPercentage = Math.min(Math.max(100 - newEditorPercentage - 5, 20), 75); // 5% gap
      
      setEditorHeight(newEditorPercentage);
      setTerminalHeight(newTerminalPercentage);
    };

    const handleMouseUp = () => {
      setIsDragging(false);
    };

    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
      document.body.style.cursor = 'ns-resize';
      document.body.style.userSelect = 'none';
    }

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
      document.body.style.cursor = 'default';
      document.body.style.userSelect = 'auto';
    };
  }, [isDragging]);

  useEffect(() => {
    if (!parseTable) {
      setFormattedParseTable('No lexical analysis data available');
      return;
    }

    try {
      let result = '<style>\n';
      result += '.parse-table { width: 100%; border-collapse: collapse; font-family: "Inter", sans-serif; background: linear-gradient(135deg, rgba(26, 26, 46, 0.5) 0%, rgba(22, 33, 62, 0.5) 100%); border-radius: 8px; overflow: hidden; }\n';
      result += '.parse-table th { padding: 6px 16px; text-align: left; background: linear-gradient(135deg, #134e4a 0%, #0f766e 100%); color: #ccfbf1; font-weight: 600; font-size: 14px; }\n'; // Dark teal
      result += '.parse-table tr:nth-child(odd) td { background-color: rgba(30, 41, 59, 0.6); }\n';
      result += '.parse-table tr:nth-child(even) td { background-color: rgba(15, 15, 35, 0.6); }\n';
      result += '.parse-table td { padding: 10px 16px; vertical-align: top; color: #f1f5f9; border-bottom: 1px solid rgba(19, 78, 74, 0.1); font-size: 13px; }\n';
      result += '.parse-table tbody tr:hover { background-color: rgba(19, 78, 74, 0.1) !important; }\n';
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
      setFormattedParseTable(`<pre style="color: #f1f5f9; font-family: 'JetBrains Mono', monospace;">${parseTable}</pre>`);
    }
  }, [parseTable]);

  useEffect(() => {
    if (!symbolTable || symbolTable.startsWith('No symbol table')) {
      setFormattedSymbolTable('No symbol table data available');
      return;
    }
    try {
      let result = '<style>\n';
      result += '.semantic-table { width: 100%; border-collapse: collapse; font-family: "Inter", sans-serif; background: linear-gradient(135deg, rgba(26, 26, 46, 0.5) 0%, rgba(22, 33, 62, 0.5) 100%); border-radius: 8px; overflow: hidden; margin-bottom: 20px; }\n';
      result += '.semantic-table th { padding: 8px 16px; text-align: left; background: linear-gradient(135deg, #451a03 0%, #78350f 100%); color: #d6d3d1; font-weight: 600; font-size: 14px; }\n'; // Dark brown
      result += '.semantic-table tr:nth-child(odd) td { background-color: rgba(30, 41, 59, 0.6); }\n';
      result += '.semantic-table tr:nth-child(even) td { background-color: rgba(15, 15, 35, 0.6); }\n';
      result += '.semantic-table td { padding: 10px 16px; vertical-align: top; color: #f1f5f9; border-bottom: 1px solid rgba(69, 26, 3, 0.1); font-size: 13px; }\n';
      result += '.semantic-table tbody tr:hover { background-color: rgba(69, 26, 3, 0.1) !important; }\n';
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
      setFormattedSymbolTable(`<pre style="color: #f1f5f9; font-family: 'JetBrains Mono', monospace;">${symbolTable}</pre>`);
    }
  }, [symbolTable]);

  useEffect(() => {
    if (!constantTable || constantTable.startsWith('No constant table')) {
      setFormattedConstantTable('No constant table data available');
      return;
    }
    try {
      let result = '<style>\n';
      result += '.constant-table { width: 100%; border-collapse: collapse; font-family: "Inter", sans-serif; background: linear-gradient(135deg, rgba(26, 26, 46, 0.5) 0%, rgba(22, 33, 62, 0.5) 100%); border-radius: 8px; overflow: hidden; }\n';
      result += '.constant-table th { padding: 8px 16px; text-align: left; background: linear-gradient(135deg, #3c1361 0%, #581c87 100%); color: #e9d5ff; font-weight: 600; font-size: 14px; }\n'; // Dark purple
      result += '.constant-table tr:nth-child(odd) td { background-color: rgba(30, 41, 59, 0.6); }\n';
      result += '.constant-table tr:nth-child(even) td { background-color: rgba(15, 15, 35, 0.6); }\n';
      result += '.constant-table td { padding: 10px 16px; vertical-align: top; color: #f1f5f9; border-bottom: 1px solid rgba(60, 19, 97, 0.1); font-size: 13px; }\n';
      result += '.constant-table tbody tr:hover { background-color: rgba(60, 19, 97, 0.1) !important; }\n';
      result += '</style>\n';
      result += '<table class="constant-table">\n';
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
      setFormattedConstantTable(`<pre style="color: #f1f5f9; font-family: 'JetBrains Mono', monospace;">${constantTable}</pre>`);
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
    <Box sx={{ 
      flexGrow: 1, 
      height: '100vh', 
      display: 'flex', 
      flexDirection: 'column', 
      overflow: 'hidden', 
      background: 'linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%)',
    }}>
      <Navbar />
      <Box sx={{ 
        display: 'flex', 
        flexGrow: 1, 
        overflow: 'hidden',
        gap: 2,
        p: 2,
      }}>
        {/* Left Panel - Editor and Terminal */}
        <Box 
          ref={containerRef}
          sx={{ 
            display: 'flex', 
            flexDirection: 'column', 
            width: '50%', 
            overflow: 'hidden',
            gap: 1,
          }}
        >
          {/* Editor Panel */}
          <Paper 
            elevation={0} 
            sx={{ 
              height: `${editorHeight}%`,
              background: 'linear-gradient(135deg, rgba(26, 26, 46, 0.8) 0%, rgba(22, 33, 62, 0.8) 100%)',
              backdropFilter: 'blur(20px)',
              border: '1px solid rgba(124, 58, 237, 0.2)',
              borderRadius: '12px',
              position: 'relative',
              overflow: 'hidden',
              minHeight: '200px',
              '&::before': {
                content: '""',
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: '2px',
                background: 'linear-gradient(90deg, #7c3aed 0%, #06b6d4 100%)',
                zIndex: 1,
              }
            }}
          >
            <Box sx={{ height: '100%', position: 'relative', pt: '2px' }}>
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
                  theme: 'vs-dark',
                  fontFamily: '"JetBrains Mono", "Fira Code", monospace',
                  cursorStyle: 'line',
                  renderLineHighlight: 'gutter',
                  selectOnLineNumbers: true,
                }}
              />
              <Box sx={{ 
                position: 'absolute', 
                top: 12, 
                right: 12,
                zIndex: 2,
              }}>
                <Button 
                  variant="contained" 
                  onClick={handleCompile}
                  disabled={compiling}
                  startIcon={<PlayArrowIcon />}
                  sx={{
                    background: compiling 
                      ? 'linear-gradient(135deg, #64748b 0%, #475569 100%)'
                      : 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
                    borderRadius: '10px',
                    fontWeight: 600,
                    px: 3,
                    py: 1,
                    boxShadow: '0 4px 15px rgba(124, 58, 237, 0.4)',
                    '&:hover': {
                      background: compiling 
                        ? 'linear-gradient(135deg, #64748b 0%, #475569 100%)'
                        : 'linear-gradient(135deg, #6d28d9 0%, #9333ea 100%)',
                      transform: compiling ? 'none' : 'translateY(-2px)',
                      boxShadow: compiling 
                        ? '0 4px 15px rgba(124, 58, 237, 0.4)'
                        : '0 6px 20px rgba(124, 58, 237, 0.6)',
                    }
                  }}
                >
                  {compiling ? 'Compiling...' : 'Compile & Run'}
                </Button>
              </Box>
            </Box>
          </Paper>

          {/* Resize Handle */}
          <Box
            sx={{
              height: '8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'ns-resize',
              background: isDragging 
                ? 'linear-gradient(90deg, rgba(124, 58, 237, 0.3) 0%, rgba(6, 182, 212, 0.3) 100%)'
                : 'transparent',
              borderRadius: '4px',
              transition: 'background 0.3s ease',
              '&:hover': {
                background: 'linear-gradient(90deg, rgba(124, 58, 237, 0.2) 0%, rgba(6, 182, 212, 0.2) 100%)',
              }
            }}
            onMouseDown={() => setIsDragging(true)}
          >
            <DragIndicatorIcon 
              sx={{ 
                color: '#64748b', 
                fontSize: '16px',
                rotate: '90deg',
                opacity: isDragging ? 1 : 0.6,
                transition: 'opacity 0.3s ease',
              }} 
            />
          </Box>

          {/* Terminal Panel */}
          <Box sx={{ 
            height: `${terminalHeight}%`,
            overflow: 'hidden',
            minHeight: '150px',
          }}>
            <Terminal 
              output={output} 
              onSendInput={handleSendInput}
              height="100%"
            />
          </Box>
        </Box>

        {/* Right Panel - Analysis Results */}
        <Box sx={{ width: '50%', overflow: 'hidden' }}>
          <Paper 
            elevation={0} 
            sx={{ 
              height: '100%', 
              overflow: 'hidden',
              background: 'linear-gradient(135deg, rgba(26, 26, 46, 0.8) 0%, rgba(22, 33, 62, 0.8) 100%)',
              backdropFilter: 'blur(20px)',
              border: '1px solid rgba(124, 58, 237, 0.2)',
              borderRadius: '12px',
              position: 'relative',
              '&::before': {
                content: '""',
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: '2px',
                background: 'linear-gradient(90deg, #7c3aed 0%, #06b6d4 100%)',
                zIndex: 1,
              }
            }}
          >
            <Box sx={{ 
              borderBottom: '1px solid rgba(124, 58, 237, 0.2)', 
              background: 'rgba(30, 41, 59, 0.5)',
              pt: '2px',
            }}>
              <Tabs
                value={tabValue}
                onChange={handleTabChange}
                variant="fullWidth"
                sx={{
                  '& .MuiTab-root': { 
                    color: '#94a3b8',
                    fontWeight: 600,
                    fontSize: '0.9rem',
                    textTransform: 'none',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      color: '#f1f5f9',
                      background: 'rgba(124, 58, 237, 0.1)',
                    }
                  },
                  '& .Mui-selected': { 
                    color: '#7c3aed !important',
                    fontWeight: 700,
                  },
                  '& .MuiTabs-indicator': { 
                    background: 'linear-gradient(90deg, #7c3aed 0%, #a855f7 100%)',
                    height: 3,
                  }
                }}
              >
                <Tab label="Lexical Analysis" />
                <Tab label="Syntax Analysis" />
                <Tab label="Semantic Analysis" />
              </Tabs>
            </Box>

            <TabPanel value={tabValue} index={0}>
              <Box
                sx={{ 
                  p: 3, 
                  overflow: 'auto', 
                  height: 'calc(100vh - 200px)',
                  background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.3) 0%, rgba(26, 26, 46, 0.3) 100%)',
                }}
                dangerouslySetInnerHTML={{ __html: formattedParseTable }}
              />
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              <Box
                sx={{ 
                  p: 3, 
                  overflow: 'auto', 
                  height: 'calc(100vh - 200px)',
                  background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.3) 0%, rgba(26, 26, 46, 0.3) 100%)',
                  color: '#f1f5f9', 
                  fontFamily: '"JetBrains Mono", "Fira Code", monospace', 
                  whiteSpace: 'pre', 
                  tabSize: 4,
                  fontSize: '13px',
                  lineHeight: 1.6,
                }}
                component="pre"
              >
                {parseTree || 'No parse tree data available'}
                <Box sx={{ mt: 3, pt: 1 }}>
                  <Button 
                    variant="contained" 
                    onClick={() => setShowParseTreeModal(true)}
                    sx={{
                      background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                      borderRadius: '10px',
                      fontWeight: 600,
                      px: 3,
                      py: 1,
                      boxShadow: '0 4px 15px rgba(99, 102, 241, 0.4)',
                      '&:hover': {
                        background: 'linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)',
                        transform: 'translateY(-2px)',
                        boxShadow: '0 6px 20px rgba(99, 102, 241, 0.6)',
                      }
                    }}
                  >
                    Show Parse Tree as Image
                  </Button>
                </Box>
              </Box>
              <Modal
                open={showParseTreeModal}
                onClose={() => setShowParseTreeModal(false)}
                sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              >
                <Box sx={{ 
                  position: 'relative', 
                  width: '100vw', 
                  height: '100vh', 
                  background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.95) 0%, rgba(26, 26, 46, 0.95) 100%)',
                  backdropFilter: 'blur(20px)',
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center' 
                }}>
                  <IconButton 
                    onClick={() => setShowParseTreeModal(false)} 
                    sx={{ 
                      position: 'absolute', 
                      top: 24, 
                      right: 24, 
                      color: '#f1f5f9',
                      background: 'rgba(124, 58, 237, 0.2)',
                      backdropFilter: 'blur(10px)',
                      '&:hover': {
                        background: 'rgba(124, 58, 237, 0.3)',
                        transform: 'scale(1.1)',
                      }
                    }}
                  >
                    <CloseIcon fontSize="large" />
                  </IconButton>
                  <img 
                    src="http://localhost:5000/api/parsetree-image/parseTree.png" 
                    alt="Parse Tree" 
                    style={{ 
                      maxWidth: '90vw', 
                      maxHeight: '90vh', 
                      borderRadius: '12px',
                      boxShadow: '0 20px 60px rgba(0, 0, 0, 0.6)',
                      border: '1px solid rgba(124, 58, 237, 0.3)',
                    }} 
                  />
                </Box>
              </Modal>
            </TabPanel>

            <TabPanel value={tabValue} index={2}>
              <Box sx={{ 
                p: 3, 
                overflow: 'auto', 
                height: 'calc(100vh - 200px)',
                background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.3) 0%, rgba(26, 26, 46, 0.3) 100%)',
              }}>
                <Typography variant="h6" sx={{ 
                  color: '#f59e0b',
                  fontWeight: 600,
                  mb: 2,
                  fontSize: '1.1rem',
                }}>
                  Symbol Table:
                </Typography>
                <Box dangerouslySetInnerHTML={{ __html: formattedSymbolTable }} />
                
                <Typography variant="h6" sx={{ 
                  mt: 4, 
                  color: '#ef4444',
                  fontWeight: 600,
                  mb: 2,
                  fontSize: '1.1rem',
                }}>
                  Constant Table:
                </Typography>
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
