include { CAT_FASTA           } from '../modules/cat_fasta'
include { EGGNOG_MAPPER       } from '../modules/eggnog_mapper'
include { MMSEQS_EASYCLUSTER  } from '../modules/mmseqs_easycluster'
include { METAEUK_EASYPREDICT } from '../modules/metaeuk_easypredict'
include { SED_FASTA_HEADER    } from '../modules/sed_fasta_header'

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

    if(params.cluster_genes || params.assemblies_are_genes) {
        ch_predictions_to_name = ch_predictions
        SED_FASTA_HEADER(ch_predictions_to_name)
        ch_versions = ch_versions.mix(SED_FASTA_HEADER.out.versions)
        
        ch_predictions_to_cat = SED_FASTA_HEADER.out.fasta
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
        ch_predictions_for_eggnog = MMSEQS_EASYCLUSTER.out.rep_fasta
            | map { meta, fasta ->
                [ meta, fasta, [] ]
            }
    } else {
        ch_predictions_for_eggnog = ch_predictions
            | combine(METAEUK_EASYPREDICT.out.gff, by: 0)
    }

    EGGNOG_MAPPER(
        ch_predictions_for_eggnog,
        eggnog_db
    )

    ch_contigs = params.cluster_genes ? MMSEQS_EASYCLUSTER.out.rep_fasta : contigs

    emit:
    contigs      = ch_contigs
    gff          = params.assemblies_are_genes ? [] : METAEUK_EASYPREDICT.out.gff
    annotations  = EGGNOG_MAPPER.out.annotations
    versions     = ch_versions
}