//
// Check input samplesheet and get read channels
//

include { fromSamplesheet } from 'plugin/nf-validation'

workflow INPUT_CHECK {
    main:
    Channel.fromSamplesheet("assemblies")
        .set { assemblies }

    if(params.reads) {
        Channel.fromSamplesheet("reads")
            | map { meta, fw, rev ->
                def single_end = rev ? false : true
                def nreads = fw.countFastq()
                if(single_end) {
                    def meta_new = meta + [ single_end: true, nreads: nreads ]
                    return [ meta_new, [fw] ]
                } else {
                    def meta_new = meta + [ single_end: false, nreads: nreads ]
                    return [ meta_new, [fw, rev] ]
                }
            }
            | set { reads }
    } else {
        reads = Channel.empty()
    }

    emit:
    assemblies // channel: [ val(meta), [ assemblies ] ]
    reads      // channel: [ val(meta), [ reads ]]            
}
