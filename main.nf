#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { validateParameters; paramsHelp } from 'plugin/nf-validation'

// Validate input parameters
if (params.validate_params) {
    validateParameters()
}

include { MGANNOTATE } from './workflows/mgannotate'

workflow {
    MGANNOTATE ()
}