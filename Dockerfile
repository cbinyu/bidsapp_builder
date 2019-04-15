# Very lightweight (~723 MB) container to base our BIDS Apps


###   Start by creating a "builder"   ###
# We'll compile all needed packages in the builder, and then when
# you build a BIDS App, you just get what you need for the actual APP

# Use an official Python runtime as a parent image
FROM python:3.5-slim as builder

## install:
# -curl, tar, unzip (to get the BIDS-Validator)
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    tar \
    unzip \
  && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


###   Install BIDS-Validator   ###

# Install nodejs and bids-validator from npm:
RUN apt-get update -qq && apt-get install -y gnupg && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update -qq && apt-get install -y nodejs && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && \
  npm install -g bids-validator


###   Install PyBIDS   ###

RUN pip install pybids

###   Clean up a little   ###

# Get rid of some test folders in some of the Python packages:
# (They are not needed for our APP):
RUN rm -fr /usr/local/lib/python3.5/site-packages/nibabel/nicom/tests && \
    rm -fr /usr/local/lib/python3.5/site-packages/nibabel/tests       && \
    rm -fr /usr/local/lib/python3.5/site-packages/nibabel/gifti/tests    \
    # Remove scipy, because we really don't need it.                     \
    # I'm leaving the EGG-INFO folder because Nipype requires it.        \
    && rm -fr /usr/local/lib/python3.5/site-packages/scipy-1.1.0-py3.5-linux-x86_64.egg/scipy



#############

###  Now, get a new machine with only the essentials  ###
FROM python:3.5-slim as Application

COPY --from=builder ./usr/local/lib/python3.5/ /usr/local/lib/python3.5/
COPY --from=builder ./usr/local/bin/           /usr/local/bin/
COPY --from=builder ./usr/lib/x86_64-linux-gnu /usr/lib/
COPY --from=builder ./usr/bin/                 /usr/bin/
COPY --from=builder ./usr/lib/node_modules/bids-validator/    /usr/lib/node_modules/bids-validator/
