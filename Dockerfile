# Stage 1: Build the Meteor application
FROM geoffreybooth/meteor-node:2.12.0

# Copy everything into the container
COPY . /source
WORKDIR /source/app

# Install production dependencies and build the bundle
RUN meteor npm install --production
RUN meteor build --directory /bundle

# Stage 2: Create the slim production image
FROM node:14-alpine
RUN apk add --no-cache bash

COPY --from=0 /bundle/bundle /app
WORKDIR /app/programs/server

RUN npm install

ENV PORT=3000
EXPOSE 3000

CMD ["node", "/app/main.js"]
