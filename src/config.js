const fs = require('fs').promises;
const path = require('path');

const connectOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true
};

async function getConfigDefaults() {
  let data = {
    server: {
      port: process.env.MVSD_PORT || 3000
    },
    db: {
      user: '',
      pass: '',
      connectOptions
    }
  };

  // vault secrets are stored in 'vault/secrets'
  let configData = await fs.readFile(path.join(__dirname, '../../vault/secrets/config.json'), 'utf-8');
  configData = JSON.parse(configData);

  data.db.user = configData && configData.DB_USER;
  data.db.pass = configData && configData.DB_PASS;

  return data;
}

module.exports = {
  getConfigDefaults
};
