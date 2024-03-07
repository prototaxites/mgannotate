include { METAEUK_EASYPREDICT } from '../../modules/metaeuk_easypredict'
include { EGGNOG_MAPPER       } from '../../modules/eggnog_mapper'

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

    ch_faa = METAEUK_EASYPREDICT.out.faa
    ch_gff = METAEUK_EASYPREDICT.out.gff

    ch_predictions = ch_faa
        | combine(ch_gff, by: 0)

    EGGNOG_MAPPER(
        ch_predictions,
        eggnog_db
    )

    emit:
    gff          = ch_gff
    annotations  = EGGNOG_MAPPER.out.annotations
    versions     = ch_versions
}