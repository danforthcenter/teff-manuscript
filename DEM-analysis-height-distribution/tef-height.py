#!/usr/bin/env python
# coding: utf-8

# # High-throughput plot height analysis with plantcv-geospatial for the 2023 Tef field experiment at the Danforth Center Field Research Site (Fisher Farm) 

# Import necessary software packages
import plantcv.plantcv as pcv
from plantcv.parallel import workflow_inputs
import plantcv.geospatial as gcv 
import os

args = workflow_inputs()

# Shapefile for cropping down the part of the image to get read into memory 
cropto = "./shapefiles/goldy-locks-boundaries.geojson"
# Read in the DSM 
dsm = gcv.read_geotif(args.image1, bands="gray", cutoff=0.995, cropto=cropto)

# Turn on plotting to print the output debug 
pcv.params.debug = "print"
pcv.params.debug_outdir = args.outdir
pcv.params.device = os.path.basename(args.image1)
# Analyze coverage for each region in the geojson
bounds = gcv.analyze.height_percentile(dsm=dsm,
                           geojson="./shapefiles/tef-plot-32615crs.geojson",
                           lower=10,
                           upper=95)
# Reset the device counter to avoid an error while auto-incrementing
pcv.params.device = 1
# Reshape the grayscale DSM data from (x,y,1) to (x,y)
dsm.array_data = dsm.array_data.reshape(dsm.array_data.shape[:2])

# Analyze and store the distribution of heights across plots 
_ = gcv.analyze.spectral_index(img=dsm,
                           geojson="./shapefiles/tef-plot-32615crs.geojson",
                           percentiles=[0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100])


# Save traits out to results file 
pcv.outputs.save_results(filename=args.result) 