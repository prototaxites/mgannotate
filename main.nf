#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    prototaxites/metannotate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/prototaxites/metannotate
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

include { validateParameters; paramsHelp } from 'plugin/nf-validation'

// Validate input parameters
if (params.validate_params) {
    validateParameters()
}

include { METANNOTATE } from './workflows/metannotate'

workflow {
    METANNOTATE ()
}