import http from 'http';
import {app} from './app.js'; 
import { Server } from 'socket.io';

const port = process.env.PORT || 4000;
const server = http.createServer(app);
const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean)
  : ['https://webadmintriptour-production.up.railway.app', 'https://triptoubookingsystem-production.up.railway.app', 'http://localhost:4200'];

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
server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
}).on("error", (error) => {
  console.error('Error starting server:', error);
});