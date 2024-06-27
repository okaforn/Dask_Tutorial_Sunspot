#!/bin/bash

# Usage: 
# for CPU:  ./start_dask_cluster_sunspot.sh 
# for GPU:  ./start_dask_cluster_sunspot.sh gpu


if [ ! -z $1 ] && [ `echo "$1" | tr '[:upper:]' '[:lower:]'` ==  "gpu" ] ; then
    GPU="-g"
    NRANKS_PER_NODE=6
else
    GPU=""
    NRANKS_PER_NODE=104
fi

NUM_NODES=$(cat $PBS_NODEFILE | wc -l)
NTOTRANKS=$(( NUM_NODES * NRANKS_PER_NODE ))

TMP_EXE=tmp_dask.sh

cat > ${TMP_EXE} << EOF
#!/bin/bash
if [ \$PALS_RANKID == 0 ]; then
    ./activate_dask_env_sunspot.sh ./start_dask_rank_sunspot.sh $GPU SCHEDULER
else
    ./activate_dask_env_sunspot.sh ./start_dask_rank_sunspot.sh $GPU
fi
EOF

chmod 755 ${TMP_EXE}
sleep 5

##mpiexec -n $NUM_NODES --ppn 1 ./${TMP_EXE}
mpiexec -n $NTOTRANKS --ppn $NRANKS_PER_NODE ./${TMP_EXE}

rm ./${TMP_EXE}
