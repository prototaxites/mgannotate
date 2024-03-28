// Check parameters
include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'
def summary_params = paramsSummaryMap(workflow)
WorkflowMgannotate.initialise(params, log)

// Import subworkflows
include { INPUT_CHECK    } from '../subworkflows/input_check'
include { DATABASES      } from '../subworkflows/databases'
include { ASSEMBLY       } from '../subworkflows/assembly'
include { FILTER_CONTIGS } from '../subworkflows/filter_contigs'
include { ANNOTATION     } from '../subworkflows/annotation'
include { COVERAGE       } from '../subworkflows/coverage'

workflow MGANNOTATE {

    ch_versions = Channel.empty()

    // Read in input data
    INPUT_CHECK()

    // Set up databases
    DATABASES()
    ch_versions = ch_versions.mix(DATABASES.out.versions)

    if(!params.assemblies_are_genes) {
        if(params.reads && !params.assemblies) {
            ASSEMBLY(
                INPUT_CHECK.out.reads
            )
            ch_assemblies = ASSEMBLY.out.assemblies
        } else {
            ch_assemblies = INPUT_CHECK.out.assemblies
        }

        if (params.filter_contigs && params.filter_taxon_list && (params.mmseqs_tax_db || params.mmseqs_tax_db_local)) {
            FILTER_CONTIGS (
                ch_assemblies,
                DATABASES.out.tax_db
            )
            ch_versions = ch_versions.mix(FILTER_CONTIGS.out.versions)
            ch_contigs  = FILTER_CONTIGS.out.filtered_fasta
        } else {
            ch_contigs  = ch_assemblies
        }
    }

    if((params.mmseqs_func_db || params.mmseqs_func_db_local)) {
        if(params.enable_annotation) {
            ANNOTATION(
                ch_contigs,
                DATABASES.out.func_db,
                DATABASES.out.eggnog_db
            )
            ch_versions = ch_versions.mix(ANNOTATION.out.versions)

            if(params.enable_coverage && params.go_list) {
                COVERAGE(
                    INPUT_CHECK.out.reads,
                    ANNOTATION.out.contigs,
                    ANNOTATION.out.annotations,
                    ANNOTATION.out.gff,
                    DATABASES.out.go_list
                )
                ch_versions = ch_versions.mix(COVERAGE.out.versions)
            }
        }
    }
}
