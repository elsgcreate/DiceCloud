FROM ubuntu:jammy

USER root
RUN adduser --system mt

RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Change "v18" to "v20" if you want a newer version
ARG NODE_MAJOR=18
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update && apt-get install -y nodejs git build-essential

USER mt

RUN curl https://install.meteor.com/ | sh

WORKDIR /home/mt
RUN git clone https://github.com/ThaumRystra/DiceCloud dicecloud
WORKDIR /home/mt/dicecloud/app
RUN npm install --production
ENV PATH=$PATH:/home/mt/.meteor
RUN meteor build --directory ~/dc/ --architecture os.linux.x86_64
WORKDIR /home/mt/dc/bundle/programs/server

# Switch to root to fix file permissions, then assign them to the 'mt' user
USER root
RUN chown -R mt:mt /home/mt/dc/bundle

# Switch back to the standard user to run npm install safely
USER mt
RUN npm install --unsafe-perm
WORKDIR /home/mt/dc/bundle
RUN rm -r /home/mt/dicecloud

ENTRYPOINT node main.js
