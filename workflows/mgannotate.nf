// Check parameters
include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'
def summary_params = paramsSummaryMap(workflow)
WorkflowMgannotate.initialise(params, log)

// Import subworkflows
include { INPUT_CHECK    } from '../subworkflows/local/input_check'
include { DATABASES      } from '../subworkflows/local/databases'
include { ASSEMBLY       } from '../subworkflows/local/assembly'
include { FILTER_CONTIGS } from '../subworkflows/local/filter_contigs'
include { ANNOTATION     } from '../subworkflows/local/annotation'
include { COVERAGE       } from '../subworkflows/local/coverage'

workflow MGANNOTATE {

    ch_versions = Channel.empty()

    // Read in input data
    INPUT_CHECK()

    // Set up databases
    DATABASES()
    ch_versions = ch_versions.mix(DATABASES.out.versions)

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
        ch_versions               = ch_versions.mix(FILTER_CONTIGS.out.versions)
        ch_contigs_for_annotation = FILTER_CONTIGS.out.filtered_mmseqs
        ch_contigs_for_coverage   = FILTER_CONTIGS.out.filtered_fasta
    } else {
        ch_contigs_for_annotation = ch_assemblies
        ch_contigs_for_coverage   = ch_assemblies
    }

    if((params.mmseqs_func_db || params.mmseqs_func_db_local) && params.eggnog_db) {
        if(params.enable_annotation) {
            ANNOTATION(
                ch_contigs_for_annotation,
                DATABASES.out.func_db,
                DATABASES.out.eggnog_db
            )
            ch_versions = ch_versions.mix(ANNOTATION.out.versions)

            if(params.enable_coverage && params.go_list) {
                COVERAGE(
                    INPUT_CHECK.out.reads,
                    ch_contigs_for_coverage,
                    ANNOTATION.out.cluster_tsv,
                    ANNOTATION.out.annotations,
                    ANNOTATION.out.gff,
                    DATABASES.out.go_list
                )
                ch_versions = ch_versions.mix(COVERAGE.out.versions)
            }
        }
    }
}
