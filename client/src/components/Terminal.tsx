import React, { useState, useEffect, useRef } from 'react';
import { Box, TextField, Typography, Paper } from '@mui/material';
import TerminalIcon from '@mui/icons-material/Terminal';

interface TerminalProps {
  output: string;
  onSendInput: (input: string) => void;
  height?: string;
}

const Terminal: React.FC<TerminalProps> = ({ output, onSendInput, height = '100%' }) => {
  const [input, setInput] = useState('');
  const outputRef = useRef<HTMLDivElement>(null);
  const resizeTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  
  useEffect(() => {
    // Debounced auto-scroll to avoid ResizeObserver errors
    if (resizeTimeoutRef.current) {
      clearTimeout(resizeTimeoutRef.current);
    }
    
    resizeTimeoutRef.current = setTimeout(() => {
      if (outputRef.current) {
        outputRef.current.scrollTop = outputRef.current.scrollHeight;
      }
    }, 100);
    
    return () => {
      if (resizeTimeoutRef.current) {
        clearTimeout(resizeTimeoutRef.current);
      }
    };
  }, [output]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput(e.target.value);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      onSendInput(input);
      setInput('');
    }
  };

  return (
    <Paper 
      elevation={0}
      sx={{ 
        display: 'flex', 
        flexDirection: 'column', 
        height: height, 
        background: 'linear-gradient(135deg, rgba(26, 26, 46, 0.8) 0%, rgba(22, 33, 62, 0.8) 100%)',
        backdropFilter: 'blur(20px)',
        border: '1px solid rgba(124, 58, 237, 0.2)',
        borderRadius: '12px',
        overflow: 'hidden',
        position: 'relative',
        '&::before': {
          content: '""',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: '2px',
          background: 'linear-gradient(90deg, #7c3aed 0%, #06b6d4 100%)',
        }
      }}
    >
      {/* Terminal Header - Reduced thickness */}
      <Box 
        sx={{ 
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          px: 2,
          py: 1, // Reduced from 2 to 1
          borderBottom: '1px solid rgba(124, 58, 237, 0.2)',
          background: 'rgba(30, 41, 59, 0.5)',
          minHeight: '40px', // Set minimum height
        }}
      >
        <TerminalIcon sx={{ fontSize: '16px', color: '#7c3aed' }} />
        <Typography 
          variant="body2" 
          sx={{ 
            color: '#94a3b8',
            fontWeight: 600,
            fontSize: '0.8rem', // Slightly smaller
          }}
        >
          Output Terminal
        </Typography>
        <Box 
          sx={{ 
            ml: 'auto',
            display: 'flex',
            gap: 0.5,
          }}
        >
          {['#ef4444', '#f59e0b', '#10b981'].map((color, index) => (
            <Box 
              key={index}
              sx={{ 
                width: 6, 
                height: 6,
                borderRadius: '50%',
                bgcolor: color,
                opacity: 0.7,
              }}
            />
          ))}
        </Box>
      </Box>

      {/* Terminal Output - Fixed height calculation */}
      <Box 
        ref={outputRef}
        sx={{ 
          flex: 1, // Take remaining space
          whiteSpace: 'pre-wrap', 
          overflowY: 'auto',
          overflowX: 'hidden', // Prevent horizontal scroll
          p: 2,
          fontSize: '13px', // Slightly smaller for more content
          fontFamily: '"JetBrains Mono", "Fira Code", monospace',
          lineHeight: 1.4, // Tighter line height
          background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.5) 0%, rgba(26, 26, 46, 0.5) 100%)',
          color: '#f1f5f9',
          minHeight: 0, // Allow flex shrinking
          wordBreak: 'break-word', // Handle long words
        }}
      >
        {output || (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, color: '#64748b', fontStyle: 'italic' }}>
            <Box 
              sx={{ 
                width: 6,
                height: 6,
                borderRadius: '50%',
                bgcolor: '#7c3aed',
                animation: 'pulse 2s infinite',
              }}
            />
            <Typography 
              variant="body2" 
              sx={{ 
                fontFamily: '"JetBrains Mono", "Fira Code", monospace',
                fontSize: '13px',
              }}
            >
              Waiting for compilation output...
            </Typography>
          </Box>
        )}
      </Box>
      
      {/* Terminal Input  */}
      <Box 
        sx={{ 
          p: 1.5, // Reduced from 2 to 1.5
          borderTop: '1px solid rgba(124, 58, 237, 0.2)',
          background: 'rgba(30, 41, 59, 0.3)',
        }}
      >
        <TextField
          variant="outlined"
          size="small"
          placeholder="Enter input for your program..."
          value={input}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          fullWidth
          sx={{ 
            '& .MuiOutlinedInput-root': {
              backgroundColor: 'rgba(15, 15, 35, 0.8)',
              fontFamily: '"JetBrains Mono", "Fira Code", monospace',
              fontSize: '13px',
              color: '#f1f5f9',
              borderRadius: '8px',
              border: '1px solid rgba(124, 58, 237, 0.3)',
              transition: 'all 0.3s ease',
              '& fieldset': {
                border: 'none',
              },
              '&:hover': {
                borderColor: 'rgba(124, 58, 237, 0.5)',
                boxShadow: '0 0 8px rgba(124, 58, 237, 0.2)',
              },
              '&.Mui-focused': {
                borderColor: '#7c3aed',
                boxShadow: '0 0 12px rgba(124, 58, 237, 0.4)',
              }
            },
            '& .MuiOutlinedInput-input': {
              padding: '8px 12px', 
              '&::placeholder': {
                color: '#64748b',
                opacity: 1,
                fontFamily: '"JetBrains Mono", "Fira Code", monospace',
              }
            }
          }}
        />
      </Box>
    </Paper>
  );
};

export default Terminal; 