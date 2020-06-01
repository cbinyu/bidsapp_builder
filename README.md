# bidsapp_builder

[![Docker image](https://img.shields.io/badge/docker-cbinyu/bidsapp__builder-brightgreen.svg?logo=docker&style=flat)](https://hub.docker.com/r/cbinyu/bidsapp_builder/tags/)
[![DOI](https://zenodo.org/badge/181539613.svg)](https://zenodo.org/badge/latestdoi/181539613)

Dockerfile to build a BIDS Apps base.

Based on Python 3.8 on Debian Buster, it installs [`bids-validator`](https://github.com/bids-standard/bids-validator) and [`pybids`](https://github.com/bids-standard/pybids)

## Usage

In the `Dockerfile` for your `BIDS-app`, enter:

```
ARG BIDSAPP_BUILDER_VERSION=v1.6
FROM cbinyu/bidsapp_builder:${BIDSAPP_BUILDER_VERSION} as builder
```

Then, just continue building your Docker image.