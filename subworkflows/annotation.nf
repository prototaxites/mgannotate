include { METAEUK_EASYPREDICT } from '../modules/metaeuk_easypredict'
include { EGGNOG_MAPPER       } from '../modules/eggnog_mapper'

workflow ANNOTATION {
    take:
    contigs
    metaeuk_db
    eggnog_db

    main:

    ch_versions = Channel.empty()

    METAEUK_EASYPREDICT ( 
        contigs, 
        metaeuk_db
    )

    ch_predictions = METAEUK_EASYPREDICT.out.codon
        | combine(METAEUK_EASYPREDICT.out.gff, by: 0)

    EGGNOG_MAPPER(
        ch_predictions,
        eggnog_db
    )

    emit:
    gff          = METAEUK_EASYPREDICT.out.gff
    annotations  = EGGNOG_MAPPER.out.annotations
    versions     = ch_versions
}