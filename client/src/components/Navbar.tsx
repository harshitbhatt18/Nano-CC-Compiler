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
import CodeIcon from '@mui/icons-material/Code';

const Navbar: React.FC = () => {
  const navigate = useNavigate();

  return (
    <AppBar 
      position="static" 
      elevation={0} 
      sx={{ 
        background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.95) 0%, rgba(26, 26, 46, 0.95) 100%)',
        backdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(124, 58, 237, 0.2)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3)',
      }}
    >
      <Container maxWidth="lg">
        <Toolbar sx={{ py: { xs: 1, sm: 1.5 }, display: 'flex', justifyContent: 'space-between' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }} onClick={() => navigate('/')}>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: { xs: 32, sm: 36 },
                height: { xs: 32, sm: 36 },
                borderRadius: '10px',
                background: 'linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)',
                boxShadow: '0 4px 15px rgba(124, 58, 237, 0.4)',
                mr: 2,
                transition: 'all 0.3s ease',
                '&:hover': {
                  transform: 'scale(1.1)',
                  boxShadow: '0 6px 20px rgba(124, 58, 237, 0.6)',
                }
              }}
            >
              <CodeIcon sx={{ fontSize: { xs: '18px', sm: '20px' }, color: 'white' }} />
            </Box>

            <Typography 
              variant="h5" 
              sx={{ 
                color: 'white',
                fontWeight: 700,
                letterSpacing: '0.5px',
                fontSize: { xs: '1.2rem', sm: '1.5rem' },
                background: 'linear-gradient(135deg, #f1f5f9 0%, #94a3b8 100%)',
                backgroundClip: 'text',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                transition: 'all 0.3s ease',
                '&:hover': {
                  background: 'linear-gradient(135deg, #7c3aed 0%, #06b6d4 100%)',
                  backgroundClip: 'text',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                }
              }}
            >
              NANO CC COMPILER
            </Typography>
          </Box>

          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button 
              color="inherit"
              onClick={() => navigate('/')}
              sx={{ 
                borderRadius: '10px',
                px: 3,
                py: 1,
                fontWeight: 600,
                color: '#94a3b8',
                background: 'rgba(30, 41, 59, 0.5)',
                border: '1px solid rgba(124, 58, 237, 0.2)',
                backdropFilter: 'blur(10px)',
                transition: 'all 0.3s ease',
                '&:hover': {
                  background: 'linear-gradient(135deg, rgba(124, 58, 237, 0.2) 0%, rgba(6, 182, 212, 0.2) 100%)',
                  borderColor: 'rgba(124, 58, 237, 0.4)',
                  color: 'white',
                  transform: 'translateY(-2px)',
                  boxShadow: '0 4px 15px rgba(124, 58, 237, 0.3)',
                }
              }}
            >
              Home
            </Button>
            <Button 
              color="inherit"
              onClick={() => navigate('/compiler')}
              sx={{ 
                borderRadius: '10px',
                px: 3,
                py: 1,
                fontWeight: 600,
                color: '#94a3b8',
                background: 'rgba(30, 41, 59, 0.5)',
                border: '1px solid rgba(124, 58, 237, 0.2)',
                backdropFilter: 'blur(10px)',
                transition: 'all 0.3s ease',
                '&:hover': {
                  background: 'linear-gradient(135deg, rgba(124, 58, 237, 0.2) 0%, rgba(6, 182, 212, 0.2) 100%)',
                  borderColor: 'rgba(124, 58, 237, 0.4)',
                  color: 'white',
                  transform: 'translateY(-2px)',
                  boxShadow: '0 4px 15px rgba(124, 58, 237, 0.3)',
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