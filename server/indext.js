// importing redis client 
const Redis = require('ioredis');
const redisClient = new Redis();

// importing scoket.io , http , express
const { Server } = require("socket.io");
const express = require("express");
const http = require("http");
const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Importing Joi and uuid
const { v4: uuidv4 } = require('uuid');
const Joi = require('joi');

const chatMessageSchema = Joi.object({
    message: Joi.string().required(),
    vehicleId: Joi.string().required(),
    vehicleType: Joi.string().required(),
    username: Joi.string().required()
})


app.get("/", (req, res) => {
    res.send("welcome to roadChat");
  });
  
// Handling messages 
io.on('connection', async (socket) => {
    console.log('a user connected');
    socket.on('message', async (data) => {
        console.log(data);
        const { value , error } = chatMessageSchema.validate(data);
        if(error){
            console.log(error);
            return;
        }
        const newMessage = {
            id: uuidv4(),
            message: value.message,
            vehicleId: value.vehicleId,
            vehicleType: value.vehicleType,
            username: value.username,
            created : new Date().getTime()
        };
    
        redisClient.lpush('chat_messages', JSON.stringify(newMessage));
        //message gets deleted after 5 minutes
        redisClient.expire(newMessage.id, 300);
        io.emit('message', newMessage);
    } );
    
    // Fetching messages from redis
    const existingMessages = await redisClient.lrange('chat_messages', 0, -1);
    
    const parsedMessages = existingMessages.map((message) => JSON.parse(message));
    
    socket.emit('messages', parsedMessages);
    
});


// start server at port 3000
server.listen(3000, () => {
    console.log('listening on *:3000');
});