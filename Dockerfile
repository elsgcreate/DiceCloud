FROM ubuntu:jammy

USER root
RUN adduser --system mt

# Install system dependencies & Node.js 18
RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

ARG NODE_MAJOR=18
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs git build-essential

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

# Temporarily switch to root to adjust bundle ownership
USER root
RUN chown -R mt /home/mt/dc/bundle

# Switch back to 'mt' to safely install server production dependencies
USER mt
RUN npm install --unsafe-perm

# Clean up source folder to save final container space
RUN rm -rf /home/mt/dicecloud

# Set execution workspace and launch command
WORKDIR /home/mt/dc/bundle
ENTRYPOINT ["node", "main.js"]
