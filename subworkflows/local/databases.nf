include { MMSEQS_DATABASES as MMSEQS_DATABASES_TAXONOMY   } from '../../modules/nf-core/mmseqs/databases/main'
include { MMSEQS_DATABASES as MMSEQS_DATABASES_FUNCTION   } from '../../modules/nf-core/mmseqs/databases/main'

workflow DATABASES {
    main:

    ch_versions = Channel.empty()

    if (params.mmseqs_tax_db) {
        MMSEQS_DATABASES_TAXONOMY ( params.mmseqs_tax_db )
        MMSEQS_DATABASES_TAXONOMY.out.database
            | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "tax_db", basename: basename]
                [meta, path]
            }
            | first
            | set { ch_mmseqs_tax_db }
        ch_versions = ch_versions.mix(MMSEQS_DATABASES_TAXONOMY.out.versions)
    } else if (params.mmseqs_tax_db_local) {
        Channel.fromPath("${params.mmseqs_tax_db_local}")
            | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "tax_db", basename: basename]
                [meta, path]
            }
            | first
            | set { ch_mmseqs_tax_db }
    }

    if (params.mmseqs_func_db) {
        MMSEQS_DATABASES_FUNCTION ( params.mmseqs_func_db )
        MMSEQS_DATABASES_FUNCTION.out.database
        | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "func_db", basename: basename]
                [meta, path]
            }
        | first
        | set { ch_mmseqs_func_db }
        ch_versions = ch_versions.mix(MMSEQS_DATABASES_FUNCTION.out.versions)
    } else if (params.mmseqs_tax_db_local) {
        Channel.fromPath("${params.mmseqs_func_db_local}")
            | map { path ->
                def basename = file("$path/*.lookup", followLinks: true).baseName[0]
                def meta = [id: "func_db", basename: basename]
                [meta, path]
            }
            | first
            | set { ch_mmseqs_func_db }
    }
    
    if(params.eggnog_db) {
        Channel.fromPath("${params.eggnog_db}")
            | first
            | set { ch_eggnog_db }
    } else {
        ch_eggnog_db = Channel.empty()
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