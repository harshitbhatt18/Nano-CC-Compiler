import React from 'react';
import { Box, Container, Typography } from '@mui/material';

const Footer: React.FC = () => {
  return (
    <Box
      component="footer"
      sx={{
        py: { xs: 2, sm: 3 },
        px: 2,
        mt: 'auto',
        background: 'linear-gradient(90deg, #1D3080 0%, #5A7CFF 100%)',
        color: 'white',
        width: '100%',
        boxShadow: '0 -4px 20px rgba(47, 75, 191, 0.25)'
      }}
    >
      <Container maxWidth="lg">
        <Typography variant="body2" sx={{ opacity: 0.9, textAlign: 'center', fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
          © {new Date().getFullYear()} - Created for educational purposes
        </Typography>
      </Container>
    </Box>
  );
};

export default Footer; 