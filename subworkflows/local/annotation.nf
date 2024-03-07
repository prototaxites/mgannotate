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

    ch_predictions = METAEUK_EASYPREDICT.out.faa

    EGGNOG_MAPPER(
        ch_clustered_predictions,
        eggnog_db
    )

    emit:
    gff          = METAEUK_EASYPREDICT.out.gff
    cluster_tsv  = MMSEQS_EASYCLUSTER.out.tsv
    annotations  = EGGNOG_MAPPER.out.annotations
    versions     = ch_versions
}