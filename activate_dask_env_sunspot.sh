#!/bin/bash
#step 2 activate the dask environment
source $IDPROOT/etc/profile.d/conda.sh && \
conda activate /lus/gila/projects/Aurora_deployment/aokafor/dask && $@
#conda activate dask && $@
