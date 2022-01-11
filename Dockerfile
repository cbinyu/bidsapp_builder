# Lightweight (~400 MB) container to base our BIDS Apps

ARG DEBIAN_VERSION=bullseye
ARG BASE_PYTHON_VERSION=3.10
ARG VIRTUAL_ENV=/opt/venv
# (don't use simply PYTHON_VERSION bc. it's an env variable)

###   Start by creating a "builder"   ###
# We'll compile all needed packages in the builder, and then when
# you build a BIDS App, you just get what you need for the actual APP

# Use an official Python runtime as a parent image
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION} as builder

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION
ARG VIRTUAL_ENV

# Upgrade pip:
RUN pip install --upgrade virtualenv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python -m pip install --upgrade pip \
    && pip --version \
    && python --version

## install:
# -curl (to get the BIDS-Validator)
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
  && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


###   Install BIDS-Validator   ###

# Install nodejs and bids-validator from npm:
ARG BIDS_VALIDATOR_VERSION=v1.8.9
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update -qq && apt-get install -y nodejs && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && \
  npm install -g bids-validator@${BIDS_VALIDATOR_VERSION} && \
  rm -r /usr/lib/node_modules/bids-validator/node_modules/\@aws-* && \
  rm -r /usr/lib/node_modules/bids-validator/node_modules/aws-*

###   Install PyBIDS   ###

# From https://github.com/bids-standard/pybids:
# "The core query functionality only requires the BIDS-Validator package.
# However, they also install scipy, numpy, nibabel, pandas...
# To make it lighterweight, I won't include them, and have the Apps
#   install them if required:

ENV PYTHON_LIB_PATH=${VIRTUAL_ENV}/lib/python${BASE_PYTHON_VERSION}

RUN pip install pybids && \
    pip uninstall --yes scipy \
                        numpy \
		        nibabel \
		        pandas && \
    rm -r ${VIRTUAL_ENV}/lib/python${BASE_PYTHON_VERSION}/site-packages/bids/tests
		  

###   Clean up a little   ###



#############

###  Now, get a new machine with only the essentials  ###
FROM python:${BASE_PYTHON_VERSION}-slim-${DEBIAN_VERSION} as Application

# This makes the BASE_PYTHON_VERSION available inside this stage
ARG BASE_PYTHON_VERSION
ARG VIRTUAL_ENV

ENV VIRTUAL_ENV=${VIRTUAL_ENV} \
    PYTHON_LIB_PATH=${VIRTUAL_ENV}/lib/python${BASE_PYTHON_VERSION} \
    PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=builder ./${VIRTUAL_ENV}/       ${VIRTUAL_ENV}/
COPY --from=builder ./usr/local/bin/            /usr/local/bin/
COPY --from=builder ./lib/x86_64-linux-gnu/     /lib/x86_64-linux-gnu/
COPY --from=builder ./usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/
#COPY --from=builder ./usr/bin/                  /usr/bin/
COPY --from=builder ./usr/bin/curl \
                    ./usr/bin/node \
                                          /usr/bin/
COPY --from=builder ./usr/lib/node_modules/bids-validator/    /usr/lib/node_modules/bids-validator/
RUN ln -s ../lib/node_modules/bids-validator/bin/bids-validator /usr/bin/bids-validator