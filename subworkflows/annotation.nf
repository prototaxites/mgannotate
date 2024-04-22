include { CAT_FASTA           } from '../modules/cat_fasta'
include { EGGNOG_MAPPER       } from '../modules/eggnog_mapper'
include { MMSEQS_EASYCLUSTER  } from '../modules/mmseqs_easycluster'
include { METAEUK_EASYPREDICT } from '../modules/metaeuk_easypredict'
include { SEQKIT_REPLACE      } from '../modules/seqkit_replace'

workflow ANNOTATION {
    take:
    contigs
    metaeuk_db
    eggnog_db

    main:
    ch_versions = Channel.empty()

    if(!params.assemblies_are_genes) {
        METAEUK_EASYPREDICT ( 
            contigs, 
            metaeuk_db
        )
        ch_versions = ch_versions.mix(METAEUK_EASYPREDICT.out.versions)
        ch_predictions = METAEUK_EASYPREDICT.out.codon
    } else {
        ch_predictions = contigs
    }

    SEQKIT_REPLACE(ch_predictions)
    ch_versions = ch_versions.mix(SEQKIT_REPLACE.out.versions)
    
    ch_predictions_to_cat = SEQKIT_REPLACE.out.fasta
        | map { meta, fasta -> [ fasta ] }
        | collect
        | map { fastas -> 
            def meta = [assemblyid: "${params.cluster_id}"]
            [ meta, fastas ]
        }

    CAT_FASTA(ch_predictions_to_cat)
    ch_versions = ch_versions.mix(CAT_FASTA.out.versions)

    ch_predictions_to_cluster = CAT_FASTA.out.fasta
    MMSEQS_EASYCLUSTER(ch_predictions_to_cluster)
    ch_versions = ch_versions.mix(MMSEQS_EASYCLUSTER.out.versions)   

    // Split large gene catalogues into chunks
    ch_predictions_for_eggnog = MMSEQS_EASYCLUSTER.out.rep_fasta
        | map { meta, fasta ->
            def split_fasta = fasta.splitFasta(size: 2.Gb, file: true)
            [ meta, split_fasta ]
        }
        | transpose
        | map { meta, fasta -> 
            def chunk_id = fasta.name.split('\\.')[1]
            def meta_new = meta + [chunk: chunk_id]
            [ meta, fasta, [] ] 
        }

    EGGNOG_MAPPER(
        ch_predictions_for_eggnog,
        eggnog_db
    )

    // Reassemble chunked eggnog output
    ch_output_annotations = EGGNOG_MAPPER.out.annotations
        | map { meta, annotations -> [ annotations ] }
        | collectFile(name: "${params.cluster_id}.emapper.annotations", keepHeader: true, skip: 5)
        | map { annotations ->
            def meta = [assemblyid: "${params.cluster_id}"]
            [ meta, annotations ]
        }

    ch_contigs = params.cluster_genes ? MMSEQS_EASYCLUSTER.out.rep_fasta : contigs

    emit:
    contigs      = ch_contigs
    gff          = params.assemblies_are_genes ? [] : METAEUK_EASYPREDICT.out.gff
    annotations  = ch_output_annotations
    versions     = ch_versions
}