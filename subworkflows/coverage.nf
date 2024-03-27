include { BOWTIE2_BUILD           } from '../modules/bowtie2_build'
include { BOWTIE2_ALIGN           } from '../modules/bowtie2_align.nf'                                                                                                                                 
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

    if(params.cluster_genes) {
        STROBEALIGN_CREATEINDEX(fasta)
        ch_versions = ch_versions.mix(STROBEALIGN_CREATEINDEX.out.versions)

        ch_index = STROBEALIGN_CREATEINDEX.out.index
            | map { meta, index ->
                def meta_join = [assemblyid: "genes"]
                [ meta_join, index ]
            }

        ch_reads_index = reads 
            | map { meta, reads ->
                def meta_join = [assemblyid: "genes"]
                def meta = meta + [assemblyid: "genes"]
                [ meta_join, meta, reads ]
            }
            | combine(ch_index, by: 0)
            | map { meta_join, meta, reads, index ->
                [ meta, reads, index ]
            }

        COVERM_CONTIGS(ch_reads_index)
        ch_versions = ch_versions.mix(COVERM_CONTIGS.out.versions)

        ch_counts = COVERM_CONTIGS.out.coverage
            | map { meta, txt ->
                def meta_join = meta.subMap("assemblyid")
                [ meta_join, meta, txt ]
            }
        
        ch_gff = gff
            | map { meta, gff ->
                def meta_join = meta.subMap("assemblyid")
                [ meta_join, gff ]
            }

    } else {
        BOWTIE2_BUILD(fasta)
        ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions)

        ch_reads_to_join = reads
            | map { meta, reads ->
                def meta_join = meta.subMap("assemblyid")
                [ meta_join, meta, reads ]
            }

        ch_indices_to_join = BOWTIE2_BUILD.out.index
            | map { meta, index ->
                def meta_join = meta.subMap("assemblyid")
                [ meta_join, index ]
            }

        ch_reads_indices = ch_reads_to_join
            | combine(ch_indices_to_join, by: 0)
            | map { meta_join, meta, reads, index ->
                [ meta, reads, index ]
            }

        BOWTIE2_ALIGN(ch_reads_indices,
                    false,
                    true)

        ch_bams = BOWTIE2_ALIGN.out.aligned
            | map { meta, bam ->
                def meta_join = meta.subMap("assemblyid")
                [ meta_join, meta, bam ]
            }

        ch_gff = gff
            | map { meta, gff ->
                def meta_join = meta.subMap("assemblyid")
                [ meta_join, gff ]
            }

        ch_bams 
            | combine(ch_gff, by: 0)
            | map { meta_join, meta, bam, gff ->
                [ meta, bam, [], gff ]
            }
            | set { ch_bam_gff }

        HTSEQ_COUNT(ch_bam_gff)
        
        ch_counts = HTSEQ_COUNT.out.txt 
            | map { meta, txt ->
                def meta_join = meta.subMap("assemblyid")
                [meta_join, meta, txt]
            }
    }

    ch_eggnog = annotations
        | map { meta, tsv ->
            def meta_join = meta.subMap("assemblyid")
            [meta_join, tsv]
        }

    ch_go_summary_input = ch_counts
        | combine(ch_eggnog, by: 0)
        | combine(ch_gff, by: 0)
        | map { meta_join, meta, counts, eggnog, gff -> 
            [meta, counts, eggnog, gff]
        }
   
    GENES_TO_GOS(
        ch_go_summary_input,
        go_list,
        params.cluster_genes ?: true
    )

    GENES_TO_GOS.out.gosummary
        | map { meta, gosummary ->
            [ gosummary ]
        }
        | collect
        | set { ch_gosummaries }

    SUMMARISE_GOS(
        ch_gosummaries,
        go_list
    )

    emit:
    versions = ch_versions
}