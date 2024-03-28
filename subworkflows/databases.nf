include { MMSEQS_DATABASES as MMSEQS_DATABASES_TAXONOMY   } from '../modules/mmseqs_databases'
include { MMSEQS_DATABASES as MMSEQS_DATABASES_FUNCTION   } from '../modules/mmseqs_databases'
include { EGGNOG_MAPPER_DATABASE                          } from '../modules/eggnog_mapper_db'

workflow DATABASES {
    main:

    ch_versions = Channel.empty()

    if (params.mmseqs_tax_db) {
        MMSEQS_DATABASES_TAXONOMY ( params.mmseqs_tax_db )
        ch_mmseqs_tax_db = MMSEQS_DATABASES_TAXONOMY.out.database
            | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "tax_db", basename: basename]
                [ meta, path ]
            }
            | first
        ch_versions = ch_versions.mix(MMSEQS_DATABASES_TAXONOMY.out.versions)
    } else if (params.mmseqs_tax_db_local) {
        ch_mmseqs_tax_db = Channel.fromPath("${params.mmseqs_tax_db_local}")
            | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "tax_db", basename: basename]
                [ meta, path ]
            }
            | first
    } else {
        ch_mmseqs_tax_db = Channel.empty()
    }

    if (params.mmseqs_func_db) {
        MMSEQS_DATABASES_FUNCTION ( params.mmseqs_func_db )
        ch_mmseqs_func_db = MMSEQS_DATABASES_FUNCTION.out.database
        | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "func_db", basename: basename]
                [ meta, path ]
            }
        | first
        ch_versions = ch_versions.mix(MMSEQS_DATABASES_FUNCTION.out.versions)
    } else if (params.mmseqs_func_db_local) {
        ch_mmseqs_func_db = Channel.fromPath("${params.mmseqs_func_db_local}")
            | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "func_db", basename: basename]
                [ meta, path ]
            }
            | first
    } else {
        ch_mmseqs_func_db = Channel.empty()
    }
    
    if(params.eggnog_db) {
        Channel.fromPath("${params.eggnog_db}")
            | first
            | set { ch_eggnog_db }
    } else {
        EGGNOG_MAPPER_DATABASE()
        ch_eggnog_db = EGGNOG_MAPPER_DATABASE.out.database
    }

    if(params.go_list) {
        Channel.fromPath("${params.go_list}")
            | first
            | set { ch_go_list }
    } else {
        ch_go_list = Channel.empty()
    }

    emit:
    tax_db      = ch_mmseqs_tax_db
    func_db     = ch_mmseqs_func_db
    eggnog_db   = ch_eggnog_db
    go_list     = ch_go_list
    versions    = ch_versions
}