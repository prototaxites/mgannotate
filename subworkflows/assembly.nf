
include { MEGAHIT   } from '../modules/megahit'
include { CAT_FASTQ } from '../modules/cat_fastq'

workflow ASSEMBLY {
    take:
    reads

    main:
    //group reads by asssemblyid and concatenate fastq files

    ch_reads = reads
        | map { meta, reads ->
            def meta_new = meta.subMap('assemblyid') + meta.subMap('single_end')
            [ meta_new, reads ]
        }
        | groupTuple(by: 0)

    ch_reads
        | map { meta, reads ->
            meta.subMap("assemblyid")
        } 
        | groupTuple()
        | map { meta ->
            if(meta.size() > 1) { 
                error("Error: For at least one assembly, you have provided both paired end and single-end reads. Reads for assembly must only be all of one kind or another at this time.") 
                }
        }

    ch_reads_branched = ch_reads
        | branch { meta, reads ->
            cat:      reads.size() >= 2 // SE: [[meta], [S1_R1, S2_R1]]; PE: [[meta], [[S1_R1, S1_R2], [S2_R1, S2_R2]]]
            skip_cat: true // Can skip merging if only single lanes
        }

    ch_reads_for_cat = ch_reads_branched.cat
        | map { meta, reads ->
            [ meta, reads.flatten() ]
        }
    ch_reads_skipped = ch_reads_branched.skip_cat
        | map { meta, reads ->
            def new_reads = meta.single_end ? reads[0] : reads.flatten()
            [ meta, new_reads ]
        }

    CAT_FASTQ(ch_reads_for_cat)

    ch_reads_for_assembly = CAT_FASTQ.out.reads
        | mix(ch_reads_skipped)

    MEGAHIT(ch_reads_for_assembly)

    ch_assemblies = MEGAHIT.out.contigs
        | map { meta, contigs ->
            def meta_new = meta + [assembler: "MEGAHIT"]
        }

    emit:
    assemblies = ch_assemblies
}