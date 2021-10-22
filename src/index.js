const express = require('express');
const http = require('http');
const mongoose = require('mongoose');
const config = require('./config');

const app = express();
const appServer = http.createServer(app);

app.get('/', (req, res) => {
  console.log('req');
  console.log(req);
  res.json('ok');
});

init()
  .catch(error => {
    console.error('ERROR:');
    console.error(error);
  });

async function init() {
  const {
    db,
    server: serverConfig
  } = await config.getConfigDefaults();

  const url = `mongodb://${db.user}:${db.pass}@mongod-statefulset-0.mongodb-service.mvsd-mongod.svc.cluster.local:27017/admin?authSource=admin`;

  mongoose.connect(url, db.connectOptions);

  mongoose.connection.on('open', () => {
    console.log('Database open!\r\n');
    console.log(`***** mongoose.connection ***** (⌐■_■)–【╦╤─ *=*=*=*=*=*=>> \r\n`, mongoose.connection);

    appServer.listen(`${serverConfig.port}`, () => {
      console.log(`listening on port: ${serverConfig.port}`);
    });
  });

  mongoose.connection.on('close', () => {
    console.log('Database disconnected');
  });

  mongoose.connection.on('error', (err) => {
    console.error(`Database connection error: ${err}`);
  });

  return true;
}
