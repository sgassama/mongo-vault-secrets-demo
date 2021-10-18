FROM node:12

## install index dependencies
## wildcard is used to ensure both package.json AND package-lock.json are copied
## where available (npm@5+)
COPY package*.json .
COPY src/ src/

# install node packages
RUN npm install

CMD [ "npm", "start" ]
