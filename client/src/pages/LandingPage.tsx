import React from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Box, 
  Button, 
  Container, 
  Typography, 
  Paper,
  Card,
  CardContent
} from '@mui/material';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box sx={{ 
      display: 'flex', 
      flexDirection: 'column', 
      minHeight: '100vh',
      bgcolor: '#F8F9FF'
    }}>
      <Navbar />

      {/* Hero Section */}
      <Box 
        sx={{
          textAlign: 'center',
          pt: { xs: 4, sm: 6 },
          pb: { xs: 6, sm: 8 },
          backgroundImage: 'linear-gradient(135deg, #E1E7FF 0%, #C1CCFF 100%)',
          borderRadius: '16px',
          position: 'relative',
          overflow: 'hidden',
          mb: { xs: 4, sm: 6 },
          mx: { xs: 2, sm: 4 },
          mt: { xs: 2, sm: 4 },
          boxShadow: '0 10px 40px rgba(47, 75, 191, 0.15)'
        }}
      >
        <Box 
          sx={{ 
            position: 'absolute', 
            width: '200px', 
            height: '200px', 
            borderRadius: '50%', 
            background: 'radial-gradient(circle, rgba(154, 173, 249, 0.6) 0%, rgba(154, 173, 249, 0) 70%)',
            top: '20px',
            right: '10%',
            zIndex: 0,
            display: { xs: 'none', sm: 'block' }
          }} 
        />

        <Box 
          sx={{ 
            position: 'absolute', 
            width: '300px', 
            height: '300px', 
            borderRadius: '50%', 
            background: 'radial-gradient(circle, rgba(90, 124, 255, 0.4) 0%, rgba(90, 124, 255, 0) 70%)',
            bottom: '-100px',
            left: '5%',
            zIndex: 0,
            display: { xs: 'none', sm: 'block' }
          }} 
        />
        
        <Container maxWidth="md" sx={{ position: 'relative', zIndex: 1 }}>
          <Typography 
            variant="h2" 
            component="h1" 
            sx={{ 
              mb: 2, 
              color: '#1D3080',
              fontWeight: 800,
              fontSize: { xs: '2rem', sm: '3rem', md: '3.75rem' }
            }}
          >
            Nano CC Compiler
          </Typography>
          <Typography 
            variant="h6" 
            sx={{ 
              mb: 4, 
              color: '#435180',
              maxWidth: '700px',
              mx: 'auto',
              fontSize: { xs: '1rem', sm: '1.25rem', md: '1.5rem' }
            }}
          >
            Explore and understand the three phases of compilation
            <br />with interactive visualizations and detailed analysis
          </Typography>
          <Button 
            variant="contained" 
            size="large"
            onClick={() => navigate('/compiler')}
            sx={{
              bgcolor: '1D3080',
              py: { xs: 1, sm: 1.5 },
              px: { xs: 3, sm: 4 },
              fontSize: { xs: '0.9rem', sm: '1.1rem' },
              boxShadow: '0 8px 20px rgba(47, 75, 191, 0.35)',
              '&:hover': {
                bgcolor: '#5A7CFF'
              }
            }}
          >
            Start Compiling
          </Button>
        </Container>
      </Box>

      {/* Features Section */}
      <Container maxWidth="lg" sx={{ mb: 6 }}>
        <Typography 
          variant="h4" 
          component="h3" 
          sx={{ 
            mb: 4, 
            textAlign: 'center', 
            fontWeight: 700,
            color: '#1F2A4B',
            fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' }
          }}
        >
          Compiler Phases
        </Typography>
        <Box sx={{ 
          display: 'flex', 
          flexWrap: 'wrap', 
          gap: { xs: 2, sm: 4 }, 
          justifyContent: 'center'
        }}>
          {[
            {
              phase: '1',
              title: 'Lexical Analysis',
              color: '#5A7CFF',
              description: 'View the tokenization process in real-time. See how your code is broken down into lexemes, with detailed token information and line numbers.'
            },
            {
              phase: '2',
              title: 'Syntax Analysis',
              color: '#42DDFF',
              description: 'Understand the parsing process and syntax validation. Visualize how your code conforms to C language grammar rules.'
            },
            {
              phase: '3',
              title: 'Semantic Analysis',
              color: '#9FAEF0',
              description: 'Explore symbol tables and constant tables. Track variable declarations, scope, and type checking in your code.'
            }
          ].map((item) => (
            <Card key={item.phase} sx={{ 
              flex: '1 1 300px',
              maxWidth: '350px',
              p: 3,
              borderRadius: '12px',
              bgcolor: 'white',
              boxShadow: '0 6px 20px rgba(47, 75, 191, 0.08)',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
              border: '1px solid rgba(159, 174, 240, 0.3)',
              '&:hover': {
                transform: 'translateY(-8px)',
                boxShadow: '0 12px 30px rgba(47, 75, 191, 0.15)',
              }
            }}>
              <Box 
                sx={{ 
                  width: { xs: '40px', sm: '48px' },
                  height: { xs: '40px', sm: '48px' },
                  borderRadius: '10px',
                  bgcolor: item.color,
                  mb: 2.5,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'white',
                  fontWeight: 'bold',
                  fontSize: { xs: '1.2rem', sm: '1.4rem' },
                  boxShadow: `0 6px 15px ${item.color}40`
                }}
              >
                {item.phase}
              </Box>
              <Typography variant="h6" sx={{ 
                fontWeight: 600,
                color: '#1F2A4B',
                mb: 1.5,
                fontSize: { xs: '1rem', sm: '1.25rem' }
              }}>
                {item.title}
              </Typography>
              <Typography variant="body1" sx={{ 
                color: '#435180',
                fontSize: { xs: '0.875rem', sm: '1rem' }
              }}>
                {item.description}
              </Typography>
            </Card>
          ))}
        </Box>
      </Container>

      <Footer />
    </Box>
  );
};

export default LandingPage; 