# Use an official Node 14 base image built on Debian Bullseye
# This fixes the broken apt-get repository issues found in Buster
FROM node:14-bullseye

USER root
RUN adduser --system --group mt

# Install Meteor's required system dependencies (git, curl, etc.)
RUN apt-get update && apt-get install -y ca-certificates curl git build-essential

# Switch to the 'mt' user to install Meteor and clone the app safely
USER mt
ENV PATH=$PATH:/home/mt/.meteor

RUN curl https://install.meteor.com/ | sh

WORKDIR /home/mt
RUN git clone https://github.com/ThaumRystra/DiceCloud dicecloud

# Install source dependencies and build the Meteor bundle
WORKDIR /home/mt/dicecloud/app
RUN npm install --production
RUN meteor build --directory /home/mt/dc/ --architecture os.linux.x86_64

# Move to the production bundle server folder
WORKDIR /home/mt/dc/bundle/programs/server

# Temporarily switch to root to grant total ownership AND read/write access
USER root
RUN chown -R mt:mt /home/mt && \
    find /home/mt -type d -exec chmod 755 {} + && \
    find /home/mt -type f -exec chmod 644 {} +

# Switch back to 'mt' to safely install server production dependencies
USER mt
RUN npm install --unsafe-perm

# Clean up source folder to save final container space
RUN rm -rf /home/mt/dicecloud

# Set execution workspace and launch command
WORKDIR /home/mt/dc/bundle
ENTRYPOINT ["node", "main.js"]
