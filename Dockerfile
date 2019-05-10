# Lightweight (~700 MB) container to base our BIDS Apps

ARG BASE_PYTHON_VERSION=3.7

###   Start by creating a "builder"   ###
# We'll compile all needed packages in the builder, and then when
# you build a BIDS App, you just get what you need for the actual APP

# Use an official Python runtime as a parent image
FROM python:${BASE_PYTHON_VERSION}-slim as builder

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION

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
RUN PYTHON_LIB_PATH=/usr/local/lib/python${BASE_PYTHON_VERSION} && \
    rm -fr ${PYTHON_LIB_PATH}/site-packages/nibabel/nicom/tests \
           ${PYTHON_LIB_PATH}/site-packages/nibabel/tests       \
           ${PYTHON_LIB_PATH}/site-packages/nibabel/gifti/tests



#############

###  Now, get a new machine with only the essentials  ###
FROM python:${BASE_PYTHON_VERSION}-slim as Application

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION
ENV PYTHON_LIB_PATH=/usr/local/lib/python${BASE_PYTHON_VERSION}

COPY --from=builder ./${PYTHON_LIB_PATH}/      ${PYTHON_LIB_PATH}/
COPY --from=builder ./usr/local/bin/           /usr/local/bin/
COPY --from=builder ./usr/lib/x86_64-linux-gnu /usr/lib/
COPY --from=builder ./usr/bin/                 /usr/bin/
COPY --from=builder ./usr/lib/node_modules/bids-validator/    /usr/lib/node_modules/bids-validator/
