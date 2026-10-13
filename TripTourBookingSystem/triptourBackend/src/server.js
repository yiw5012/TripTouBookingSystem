import http from 'http';
import {app} from './app.js'; 
import { Server } from 'socket.io';

const port = process.env.PORT || 4000;
const server = http.createServer(app);
const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean)
  : ['http://localhost:4200', 'http://localhost:4000', 'https://triptoubookingsystem-production.up.railway.app', 'http://localhost:5000'];

const io = new Server(server, {
  cors: {
    origin: allowedOrigins,
    credentials: true
  }
});

app.set('io', io);

io.on('connection', (socket) => {
  socket.on('join_order', (orderId) => {
    socket.join(orderId);
  });
});
server.listen(port,'0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
}).on("error", (error) => {
  console.error('Error starting server:', error);
});