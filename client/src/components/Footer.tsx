import React from 'react';
import { Box, Container, Typography } from '@mui/material';

const Footer: React.FC = () => {
  return (
    <Box
      component="footer"
      sx={{
        py: { xs: 3, sm: 4 },
        px: 2,
        mt: 'auto',
        background: 'linear-gradient(135deg, rgba(15, 15, 35, 0.95) 0%, rgba(26, 26, 46, 0.95) 100%)',
        backdropFilter: 'blur(20px)',
        borderTop: '1px solid rgba(124, 58, 237, 0.2)',
        color: '#94a3b8',
        width: '100%',
        boxShadow: '0 -8px 32px rgba(0, 0, 0, 0.3)',
        position: 'relative',
        overflow: 'hidden',
        '&::before': {
          content: '""',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: '2px',
          background: 'linear-gradient(90deg, #7c3aed 0%, #06b6d4 50%, #a855f7 100%)',
        }
      }}
    >
      <Container maxWidth="lg">
        <Typography 
          variant="body2" 
          sx={{ 
            textAlign: 'center', 
            fontSize: { xs: '0.875rem', sm: '1rem' },
            fontWeight: 500,
            opacity: 0.9,
            background: 'linear-gradient(135deg, #f1f5f9 0%, #94a3b8 100%)',
            backgroundClip: 'text',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
          }}
        >
          © {new Date().getFullYear()} Nano CC Compiler - Created for educational purposes
        </Typography>
      </Container>
    </Box>
  );
};

export default Footer; 