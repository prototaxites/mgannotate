include { COUNT_FASTQ     } from '../modules/count_fastq'
include { fromSamplesheet } from 'plugin/nf-validation'

workflow INPUT_CHECK {
    main:
    if(params.assemblies) {
        ch_assemblies = Channel.fromSamplesheet("assemblies")
    } else {
        ch_assemblies = Channel.empty()
    }

    if(params.reads) {
        ch_reads_to_count = Channel.fromSamplesheet("reads")
            | map { meta, fw, rev ->
                def single_end = rev ? false : true
                if(single_end) {
                    def meta_new = meta + [ single_end: true ]
                    return [ meta_new, [fw] ]
                } else {
                    def meta_new = meta + [ single_end: false ]
                    return [ meta_new, [fw, rev] ]
                }
            }

        COUNT_FASTQ(ch_reads_to_count)

        ch_reads = COUNT_FASTQ.out.fastq
            | map { meta, fastq, nreads ->
                def meta_new = meta + [ nreads: nreads ]
                [ meta_new, fastq ]
            }
    } else {
        ch_reads = Channel.empty()
    }

    emit:
    ch_assemblies // channel: [ val(meta), [ assemblies ] ]
    ch_reads      // channel: [ val(meta), [ reads ]]            
}
