import express from 'express';
import http from 'http';
import mysql from 'mysql2';
import {app} from './app.js'; 
import { Server } from 'socket.io';

const port = process.env.PORT || 4000;
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

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