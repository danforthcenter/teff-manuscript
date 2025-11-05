#!/usr/bin/env python
# coding: utf-8

# # High-throughput plot height analysis with plantcv-geospatial for the 2023 Tef field experiment at the Danforth Center Field Research Site (Fisher Farm) 

# Import necessary software packages
import plantcv.plantcv as pcv
from plantcv.parallel import workflow_inputs
import plantcv.geospatial as gcv 
import random

args = workflow_inputs()

# Shapefile for cropping down the part of the image to get read into memory 
cropto = "./goldy-locks-boundaries.geojson"
# Read in the DSM 
dsm = gcv.read_geotif(args.image1, bands="gray", cutoff=0.995, cropto=cropto)

# Turn on plotting to print the output debug 
pcv.params.debug = "print"
pcv.params.device = random.randrange(0,100000,1)
# Analyze coverage for each region in the geojson
bounds = gcv.analyze.height_percentile(dsm=dsm,
                           geojson="./haley-plots.geojson",
                           lower=10,
                           upper=95,
                           label="default")

# Save traits out to results file 
pcv.outputs.save_results(filename=args.result) 