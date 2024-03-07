//
// Check input samplesheet and get read channels
//

// Fix nf-validation at 1.1.3 as breaking changes with 2.0
include { fromSamplesheet } from 'plugin/nf-validation@1.1.3'

workflow INPUT_CHECK {
    main:
    if(params.assemblies) {
        Channel.fromSamplesheet("assemblies")
            .set { assemblies }
    } else {
        assemblies = Channel.empty()
    }

    if(params.reads) {
        Channel.fromSamplesheet("reads")
            | map { meta, fw, rev ->
                def single_end = rev ? false : true
                def nreads = file(fw).countFastq()
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
