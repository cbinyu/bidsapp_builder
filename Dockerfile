# Lightweight (~450 MB) container to base our BIDS Apps

ARG DEBIAN_VERSION=buster
ARG BASE_PYTHON_VERSION=3.8
# (don't use simply PYTHON_VERSION bc. it's an env variable)

###   Start by creating a "builder"   ###
# We'll compile all needed packages in the builder, and then when
# you build a BIDS App, you just get what you need for the actual APP

# Use an official Python runtime as a parent image
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION} as builder

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION

## install:
# -curl, tar, unzip (to get the BIDS-Validator)
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
  && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


###   Install BIDS-Validator   ###

# Install nodejs and bids-validator from npm:
ARG BIDS_VALIDATOR_VERSION=1.3.8
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update -qq && apt-get install -y nodejs && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && \
  npm install -g bids-validator@${BIDS_VALIDATOR_VERSION} && \
  rm -r /usr/lib/node_modules/bids-validator/tests


###   Install PyBIDS   ###

# From https://github.com/bids-standard/pybids:
# "The core query functionality only requires the BIDS-Validator package.
# However, they also install scipy, numpy, nibabel, pandas...
# To make it lighterweight, I won't include them, and have the Apps
#   install them if required:

ENV PYTHON_LIB_PATH=/usr/local/lib/python${BASE_PYTHON_VERSION}

RUN pip install pybids && \
    pip uninstall --yes scipy \
                        numpy \
		        nibabel \
		        pandas && \
    rm -r ${PYTHON_LIB_PATH}/site-packages/bids/tests
		  

###   Clean up a little   ###




#############

###  Now, get a new machine with only the essentials  ###
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION} as Application

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION
ENV PYTHON_LIB_PATH=/usr/local/lib/python${BASE_PYTHON_VERSION}

COPY --from=builder ./${PYTHON_LIB_PATH}/       ${PYTHON_LIB_PATH}/
COPY --from=builder ./usr/local/bin/            /usr/local/bin/
COPY --from=builder ./lib/x86_64-linux-gnu/     /lib/x86_64-linux-gnu/
COPY --from=builder ./usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/
#COPY --from=builder ./usr/bin/                  /usr/bin/
COPY --from=builder ./usr/bin/curl \
                    ./usr/bin/node \
                                          /usr/bin/
COPY --from=builder ./usr/lib/node_modules/bids-validator/    /usr/lib/node_modules/bids-validator/
RUN ln -s ../lib/node_modules/bids-validator/bin/bids-validator /usr/bin/bids-validator