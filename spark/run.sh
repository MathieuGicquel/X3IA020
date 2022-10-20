#!/bin/bash

# To create a bucket : https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-cli
# Examples of usage : 
#   ./run.sh x3ia020 x3ia020-bucket cluster-small-spark-1 1 gs://public_lddm_data/small_page_links.nt &> ../log/small-spark-1.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-small-spark-2 2 gs://public_lddm_data/small_page_links.nt &> ../log/small-spark-2.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-small-spark-3 3 gs://public_lddm_data/small_page_links.nt &> ../log/small-spark-3.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-small-spark-4 4 gs://public_lddm_data/small_page_links.nt &> ../log/small-spark-4.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-small-spark-5 5 gs://public_lddm_data/small_page_links.nt &> ../log/small-spark-5.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-normal-spark-1 1 gs://public_lddm_data/page_links_en.nt.bz2 &> ../log/normal-spark-1.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-normal-spark-2 2 gs://public_lddm_data/page_links_en.nt.bz2 &> ../log/normal-spark-2.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-normal-spark-3 3 gs://public_lddm_data/page_links_en.nt.bz2 &> ../log/normal-spark-3.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-normal-spark-4 4 gs://public_lddm_data/page_links_en.nt.bz2 &> ../log/normal-spark-4.log
#   ./run.sh x3ia020 x3ia020-bucket cluster-normal-spark-5 5 gs://public_lddm_data/page_links_en.nt.bz2 &> ../log/normal-spark-5.log

set -o xtrace

PROJECT_ID=$1
BUCKET_NAME=$2
CLUSTER_ID=$3
NUM_WORKERS=$4
INPUT_FILE=$5

## upload code
gsutil cp pagerank.py "gs://$BUCKET_NAME/"

## Clean out directory
gsutil rm -rf "gs://$BUCKET_NAME/out/$CLUSTER_ID/"

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
gcloud dataproc jobs submit pyspark \
    --project "$PROJECT_ID" \
    --region europe-west1 \
    --cluster "$CLUSTER_ID" \
    "gs://$BUCKET_NAME/pagerank.py"  \
    -- "$INPUT_FILE" 3 "gs://$BUCKET_NAME/out/$CLUSTER_ID/"

## delete the cluster
yes | gcloud dataproc clusters delete $CLUSTER_ID \
    --region europe-west1 \
    --project "$PROJECT_ID"