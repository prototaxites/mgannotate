//
// Check input samplesheet and get read channels
//

include { fromSamplesheet } from 'plugin/nf-validation'

workflow INPUT_CHECK {
    main:
    Channel.fromSamplesheet("input")
        .set { assemblies }

    emit:
    assemblies                                // channel: [ val(meta), [ reads ] ]
}
