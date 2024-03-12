include { MMSEQS_CREATEDB      } from '../../modules/mmseqs_createdb'
include { MMSEQS_TAXONOMY      } from '../../modules/mmseqs_taxonomy'
include { MMSEQS_FILTERTAXDB   } from '../../modules/mmseqs_filtertaxdb'
include { MMSEQS_CREATESUBDB   } from '../../modules/mmseqs_createsubdb'
include { MMSEQS_CONVERT2FASTA } from '../../modules/mmseqs_convert2fasta'

workflow FILTER_CONTIGS {
    take:
    assemblies  // val(meta), path(contigs)
    taxdb       // val(db_meta), path(mmseqs_seqtaxdb)

    main:
    ch_versions = Channel.empty()

    MMSEQS_CREATEDB(assemblies)
    MMSEQS_CREATEDB.out.database 
        | map { meta, database ->
            def basename = file("$database/*.lookup", followLinks: true).baseName[0]
            meta_new = meta + [basename: basename]
            [meta_new, database]
        }
        | set { ch_assembly_mmseqs_dbs }
    ch_versions = ch_versions.mix(MMSEQS_CREATEDB.out.versions)

    MMSEQS_TAXONOMY(ch_assembly_mmseqs_dbs, taxdb)
    MMSEQS_TAXONOMY.out.database
        | map { meta, database ->
            def basename = file("$database/*.index", followLinks: true).baseName[0]
            meta_new = meta + [basename: basename]
            [meta_new, database]
        }
        | set { ch_mmseqs_tax_dbs }
    ch_versions = ch_versions.mix(MMSEQS_TAXONOMY.out.versions)

    MMSEQS_FILTERTAXDB(ch_mmseqs_tax_dbs, taxdb)
    ch_versions = ch_versions.mix(MMSEQS_FILTERTAXDB.out.versions)

    // Join mmseqs sequence DBs with taxonomy DBs
    ch_sequence_dbs = ch_assembly_mmseqs_dbs 
        | map { meta, database ->
            def meta_new = meta - meta.subMap('basename')
            [meta_new, database]
        }
    ch_filt_tax_dbs = MMSEQS_FILTERTAXDB.out.database
        | map { meta, database ->
            def meta_new = meta - meta.subMap('basename')
            [meta_new, database]
        }

    ch_seq_filt_tax_dbs = ch_filt_tax_dbs
        | combine(ch_sequence_dbs, by: 0)
        | map { meta, read_ids, seqdb ->
            def basename = file("$seqdb/*.lookup", followLinks: true).baseName[0]
            def meta_new = meta + [basename: basename]
            [meta_new, read_ids, seqdb]
        }

    MMSEQS_CREATESUBDB(ch_seq_filt_tax_dbs)

    MMSEQS_CREATESUBDB.out.database
        | map { meta, database ->
            def basename = file("$database/*.lookup", followLinks: true).baseName[0]
            def meta_new = meta + [basename: basename]
            [meta_new, database]
        }
        | set { ch_filtered_assemblies }

    MMSEQS_CONVERT2FASTA( ch_filtered_assemblies ) 

    emit:
    filtered_mmseqs     = ch_filtered_assemblies
    filtered_fasta      = MMSEQS_CONVERT2FASTA.out.fasta
    versions            = ch_versions
}