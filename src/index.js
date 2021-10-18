const express = require('express');
const http = require('http');
const mongoose = require('mongoose');
const config = require('./config');

const PORT = 3000;

const app = express();
const server = http.createServer(app);

app.get('/', (req, res) => {
  res.json('ok');
});

server.listen(`${PORT}`, () => {
  console.log(`listening on port: ${PORT}`);

  init()
    .then(() => console.log('App initiated...'))
    .catch(error => {
      console.error('ERROR:');
      console.error(error);
    });
});

async function init() {
  const { db } = await config.getConfigDefaults();

  const url = `mongodb://${db.user}:${db.pass}@mongod-statefulset-0.mongodb-service.mvsd-mongod.svc.cluster.local:27017/admin?authSource=admin`;

  await mongoose.connect(url, db.connectOptions);

  mongoose.connection.on('connected', () => {
    console.log('Database connected');
  });

  mongoose.connection.on('close', () => {
    console.log('Database disconnected');
  });

  mongoose.connection.on('error', (err) => {
    console.error(`Database connection error: ${err}`);
  });

  return true;
}
