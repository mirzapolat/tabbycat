# Docker file lists all the commands needed to setup a fresh linux instance to
# run the application specified. docker-compose does not use this.

# Grab a python image
FROM python:3.11

WORKDIR /tcd

# Just needed for all things python (note this is setting an env variable)
ENV PYTHONUNBUFFERED 1
# Needed for correct settings input
ENV IN_DOCKER 1
# Needed for NVM
ENV NVM_DIR "/root/.nvm"
# Set git to use HTTPS (SSH is often blocked by firewalls)
RUN git config --global url."https://".insteadOf git://

# Setup Node/NPM
RUN apt-get update && \
    apt-get install -y curl nginx && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash - && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install node 22.4.0 && \
    nvm use node

# Install our node/python requirements
RUN pip install pipenv
ADD Pipfile Pipfile.lock /tcd/
RUN pipenv install --system --deploy && \
    pipenv --clear
ADD package.json package-lock.json /tcd/
RUN . "$NVM_DIR/nvm.sh" && \
    npm ci --omit=dev && \
    npx update-browserslist-db@latest && \
    npm cache clean --force

# Copy all our files
ADD babel.config.js crowdin.yml ProcfileMulti.docker render.yaml vue.config.js /tcd/
ADD bin/ /tcd/bin/
ADD config/ /tcd/config/
ADD data/ /tcd/data/
ADD tabbycat/ /tcd/tabbycat/

# Compile all the static files
RUN . "$NVM_DIR/nvm.sh" && npm run build
RUN python ./tabbycat/manage.py collectstatic --noinput -v 0
