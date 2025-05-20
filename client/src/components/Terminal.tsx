import React, { useState, useEffect, useRef } from 'react';
import { Box, TextField, Typography } from '@mui/material';

interface TerminalProps {
  output: string;
  onSendInput: (input: string) => void;
}

const Terminal: React.FC<TerminalProps> = ({ output, onSendInput }) => {
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
    <Box sx={{ 
      display: 'flex', 
      flexDirection: 'column', 
      height: '100%', 
      bgcolor: 'var(--secondary-color)', 
      color: '#f0f0f0',
      fontFamily: 'monospace',
      p: 1,
      overflow: 'hidden',
      borderRadius: '4px'
    }}>
      <Box 
        ref={outputRef}
        sx={{ 
          flexGrow: 1, 
          whiteSpace: 'pre-wrap', 
          overflowY: 'auto',
          p: 1,
          fontSize: '14px'
        }}
      >
        {output || (
          <Typography 
            variant="body2" 
            sx={{ 
              fontStyle: 'italic',
              color: 'var(--accent-color)'
            }}
          >
            Output will appear here after compilation...
          </Typography>
        )}
      </Box>
      
      <TextField
        variant="outlined"
        size="small"
        placeholder="Enter input for the program..."
        value={input}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        fullWidth
        sx={{ 
          mt: 1,
          '& .MuiOutlinedInput-root': {
            backgroundColor: 'var(--primary-color)',
            fontFamily: 'monospace',
            fontSize: '14px',
            color: 'white',
            '&:hover fieldset': {
              borderColor: 'var(--highlight-color)',
            },
            '&.Mui-focused fieldset': {
              borderColor: 'var(--accent-color)',
            }
          },
          '& .MuiOutlinedInput-input::placeholder': {
            color: 'var(--accent-color)',
            opacity: 0.7
          }
        }}
      />
    </Box>
  );
};

export default Terminal; 