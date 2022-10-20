#!/bin/bash

# To create a bucket : https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-cli
# Examples of usage : 
#   ./run.sh x3ia020 cluster-small-pig-1 1 ./pagerank_small.py &> ../log/small-pig-1.log
#   ./run.sh x3ia020 cluster-small-pig-2 2 ./pagerank_small.py &> ../log/small-pig-2.log
#   ./run.sh x3ia020 cluster-small-pig-3 3 ./pagerank_small.py &> ../log/small-pig-3.log
#   ./run.sh x3ia020 cluster-small-pig-4 4 ./pagerank_small.py &> ../log/small-pig-4.log
#   ./run.sh x3ia020 cluster-small-pig-5 5 ./pagerank_small.py &> ../log/small-pig-5.log
#   ./run.sh x3ia020 cluster-normal-pig-1 1 ./pagerank_normal.py &> ../log/normal-pig-1.log
#   ./run.sh x3ia020 cluster-normal-pig-2 2 ./pagerank_normal.py &> ../log/normal-pig-2.log
#   ./run.sh x3ia020 cluster-normal-pig-3 3 ./pagerank_normal.py &> ../log/normal-pig-3.log
#   ./run.sh x3ia020 cluster-normal-pig-4 4 ./pagerank_normal.py &> ../log/normal-pig-4.log
#   ./run.sh x3ia020 cluster-normal-pig-5 5 ./pagerank_normal.py &> ../log/normal-pig-5.log

set -o xtrace

PROJECT_ID=$1 
BUCKET_NAME="x3ia020-bucket"
CLUSTER_ID=$2
NUM_WORKERS=$3
SCRIPT_FILE=$4

## upload code
gsutil cp "$SCRIPT_FILE" "gs://$BUCKET_NAME/"

## Clean out directory
gsutil rm -rf "gs://$BUCKET_NAME/out"

## create the cluster
if [[ $NUM_WORKERS == 1 ]]; then
    NUM_WORKERS_ARGS="--single-node"
else
    NUM_WORKERS_ARGS="--num-workers $NUM_WORKERS"
fi

gcloud dataproc clusters create "$CLUSTER_ID" \
    --enable-component-gateway \
    --region europe-west1 \
    --zone europe-west1-c \
    --master-machine-type n1-standard-4 \
    --master-boot-disk-size 500 \
    ${NUM_WORKERS_ARGS} \
    --worker-machine-type n1-standard-4 \
    --worker-boot-disk-size 500 \
    --image-version 2.0-debian10 \
    --project "$PROJECT_ID"


## run
gcloud dataproc jobs submit pig \
    --project "$PROJECT_ID" \
    --region europe-west1 \
    --cluster "$CLUSTER_ID" \
    -f "gs://$BUCKET_NAME/$SCRIPT_FILE"

## delete the cluster
yes | gcloud dataproc clusters delete "$CLUSTER_ID" \
    --region europe-west1 \
    --project "$PROJECT_ID"
