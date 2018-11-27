#!/bin/bash

iter=0

while test "${iter}" -lt 10
do
    echo "${iter}"
    iter=$(echo "${iter} + 1" | bc)
done
