include { MMSEQS_EASYCLUSTER  } from '../../modules/mmseqs_easycluster'
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

    MMSEQS_EASYCLUSTER(ch_predictions)
    ch_clustered_predictions = MMSEQS_EASYCLUSTER.out.rep_fasta
        | map { meta, fasta ->
            [meta, fasta, []]
        }

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