include { MMSEQS_CREATEDB     } from '../../modules/local/mmseqs_createdb'
include { MMSEQS_EASYCLUSTER  } from '../../modules/local/mmseqs_easycluster'
include { METAEUK_EASYPREDICT } from '../../modules/local/metaeuk_easypredict'
include { EGGNOG_MAPPER       } from '../../modules/local/eggnog_mapper'

workflow ANNOTATION {
    take:
    contigs
    metaeuk_db
    eggnog_db

    main:

    ch_versions = Channel.empty()

    if (!(params.filter_contigs && params.filter_taxon_list && (params.mmseqs_tax_db || params.mmseqs_tax_db_local))) {
        MMSEQS_CREATEDB(contigs)
        MMSEQS_CREATEDB.out.database 
        | map { meta, database ->
            def basename = file("$database/*.lookup", followLinks: true).baseName[0]
            meta_new = meta + [basename: basename]
            [meta_new, database]
        }
        | set { ch_mmseqs_db }
    } else {
        ch_mmseqs_db = contigs
    }

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