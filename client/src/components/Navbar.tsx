import React from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  AppBar, 
  Toolbar, 
  Typography, 
  Box,
  Container,
  Button
} from '@mui/material';

const Navbar: React.FC = () => {
  const navigate = useNavigate();

  return (
    <AppBar 
      position="static" 
      elevation={0} 
      sx={{ 
        background: 'linear-gradient(90deg, #1D3080 0%, #5A7CFF 100%)',
        boxShadow: '0 4px 20px rgba(47, 75, 191, 0.25)'
      }}
    >
      <Container maxWidth="lg">
        <Toolbar sx={{ py: { xs: 0.5, sm: 1 }, display: 'flex', justifyContent: 'space-between' }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: { xs: 28, sm: 32 },
                height: { xs: 28, sm: 32 },
                borderRadius: '8px',
                bgcolor: 'rgba(255, 255, 255, 0.2)',
                fontSize: { xs: '16px', sm: '18px' },
                mr: 2
              }}
            >
              ⚙️
            </Box>

            <Typography 
              variant="h5" 
              onClick={() => navigate('/compiler')}
              sx={{ 
                textDecoration: 'none',
                color: 'white',
                fontWeight: 700,
                letterSpacing: '0.5px',
                fontSize: { xs: '1.2rem', sm: '1.5rem' },
                cursor: 'pointer',
                my: { xs: 1, sm: 0 },
              }}
            >
              NANO CC COMPILER
            </Typography>
          </Box>

          <Box sx={{ display: 'flex', gap: 1, }}>
            <Button 
              color="inherit"
              onClick={() => navigate('/')}
              sx={{ 
                borderRadius: '8px',
                '&:hover': {
                  backgroundColor: 'rgba(255, 255, 255, 0.15)'
                }
              }}
            >
              Home
            </Button>
            <Button 
              color="inherit"
              onClick={() => navigate('/compiler')}
              sx={{ 
                borderRadius: '8px',
                '&:hover': {
                  backgroundColor: 'rgba(255, 255, 255, 0.15)'
                }
              }}
            >
              Compiler
            </Button>
          </Box>
        </Toolbar>
      </Container>
    </AppBar>
  );
};

export default Navbar; 