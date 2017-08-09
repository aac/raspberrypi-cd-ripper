#!/bin/bash

body="{\"artist\":\"$1\",\"album\":\"$2\"}"
curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d "$body" **ZAPIER_WEBHOOK**
