#!/bin/bash
# vLLM entrypoint script
# This script is packaged into the workload ConfigMap and extracted by Kuiper at launch time.
# It is not executed by the container - the container uses the image's default entrypoint.
echo "vLLM entrypoint: workload launched"
