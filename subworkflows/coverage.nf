include { BOWTIE2_BUILD           } from '../modules/bowtie2_build'
include { BOWTIE2_ALIGN           } from '../modules/bowtie2_align.nf'                                         
include { COVERM_CONTIGS          } from '../modules/coverm_contigs'                                                                                        
include { HTSEQ_COUNT             } from '../modules/htseq_count.nf'                                                                                                                                 
include { GENES_TO_GOS            } from '../modules/genes_to_gos'                                                                                                                                 
include { STROBEALIGN_CREATEINDEX } from '../modules/strobealign_createindex'                                                                                                                                 
include { SUMMARISE_GOS           } from '../modules/summarise_gos'                                                                                                                                 

workflow COVERAGE {
    take:
    reads
    fasta
    annotations
    gff
    go_list

    main:
    ch_versions = Channel.empty()

    ch_reads_index = reads 
        | map { meta, reads ->
            def meta_join = [assemblyid: "${params.cluster_id}"]
            def meta_new = meta + [assemblyid: "${params.cluster_id}"]
            [ meta_join, meta_new, reads ]
        }
        | combine(fasta, by: 0)
        | map { meta_join, meta, reads, fasta ->
            [ meta, reads, [], fasta ]
        }

    COVERM_CONTIGS(ch_reads_index)
    ch_versions = ch_versions.mix(COVERM_CONTIGS.out.versions)

    ch_counts = COVERM_CONTIGS.out.coverage
        | map { meta, txt ->
            def meta_join = meta.subMap("assemblyid")
            [ meta_join, meta, txt ]
        }
    
    ch_eggnog = annotations
        | map { meta, tsv ->
            def meta_join = meta.subMap("assemblyid")
            [meta_join, tsv]
        }

    ch_go_summary_input = ch_counts
        | combine(ch_eggnog, by: 0)
        | map { meta_join, meta, counts, eggnog -> 
            [ meta, counts, eggnog, [] ]
        }
    
    if(params.go_list) { 
        GENES_TO_GOS(
            ch_go_summary_input,
            go_list
        )

        ch_gosummaries = GENES_TO_GOS.out.gosummary
            | map { meta, gosummary ->
                [ gosummary ]
            }
            | collect

        SUMMARISE_GOS(
            ch_gosummaries,
            go_list
        )
    }

    emit:
    versions = ch_versions
}