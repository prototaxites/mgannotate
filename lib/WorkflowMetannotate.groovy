//
// This file holds several functions specific to the workflow/metannotate.nf in the prototaxites/metannotate pipeline
//

import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class WorkflowMetannotate {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        if(!(params.reads || params.assemblies)) {
            Nextflow.error("Error: no reads or assemblies provided! Pipeline has no input and will not run.")
        }
        if(params.mmseqs_tax_db && params.mmseqs_tax_db_local) {
            Nextflow.error("Error: both --mmseqs_tax_db and --mmseqs_tax_db_local have been set! Please provide only one or the other.")
        }
        if(params.mmseqs_func_db && params.mmseqs_func_db_local) {
            Nextflow.error("Error: both --mmseqs_func_db and --mmseqs_func_db_local have been set! Please provide only one or the other.")
        }
        if(!(params.mmseqs_func_db || params.mmseqs_func_db_local) && !params.eggnog_db) {
            log.warn("Warning: No functional database (-mmseqs_func_db or --mmseqs_func_db_local) has been provided. Annotation will be skipped.")
        }
        if(params.filter_contigs && !(params.mmseqs_tax_db || params.mmseqs_tax_db_local)) {
            log.warn("Warning: --filter_contigs is set but an MMSeqs2 taxonomic database (--mmseqs_tax_db or --mmseqs_tax_db_local) has not been specified. Contig filtering will be disabled.")
        }
        if(params.filter_contigs && !params.filter_taxon_list) {
            log.warn("Warning: --filter_contigs is set but no taxon list for filtering has been provided. Contig filtering will be disabled.")
        }
        if(params.enable_coverage && !params.go_list) {
            log.warn("Warning: Coverage calculation will be skipped as --go_list not provided!")
        }
    }
}
