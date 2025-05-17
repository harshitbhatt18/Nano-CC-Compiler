import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Button, Container, Typography, Paper } from '@mui/material';

const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Container maxWidth="md" sx={{ height: '100vh', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
      <Paper
        elevation={3}
        sx={{
          p: 4,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          backgroundColor: 'rgba(30, 30, 30, 0.8)',
        }}
      >
        <Typography variant="h2" component="h1" gutterBottom>
          Nano CC Compiler
        </Typography>
        <Typography variant="h5" component="h2" gutterBottom align="center" sx={{ mb: 4 }}>
          A simple C compiler for educational purposes
        </Typography>
        <Typography variant="body1" paragraph align="center" sx={{ mb: 4 }}>
          Nano CC Compiler is a lightweight C compiler that demonstrates the key phases of compilation:
          lexical analysis, syntax analysis, and semantic analysis. It's designed to help you understand
          how compilers work.
        </Typography>
        <Box sx={{ display: 'flex', justifyContent: 'center', gap: 2 }}>
          <Button 
            variant="contained" 
            color="primary" 
            size="large" 
            onClick={() => navigate('/compiler')}
          >
            Get Started
          </Button>
        </Box>
      </Paper>
    </Container>
  );
};

export default LandingPage; 