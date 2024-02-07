process MMSEQS_EASYCLUSTER {
    tag "${meta.assemblyid}"
    label 'process_medium'

    conda "bioconda::mmseqs2=14.7e284"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mmseqs2:14.7e284--pl5321h6a68c12_2':
        'biocontainers/mmseqs2:14.7e284--pl5321h6a68c12_2' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_rep_seq.fasta")  , emit: rep_fasta
    tuple val(meta), path("*_all_seqs.fasta") , emit: all_seqs_fasta
    tuple val(meta), path("*_cluster.tsv")    , emit: tsv
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mmseqs easy-cluster \\
        ${fasta} \\
        ${prefix} \\
        tmp/ \\
        --threads ${task.cpus} \\
        ${args} \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs | grep 'Version' | sed 's/MMseqs2 Version: //')
    END_VERSIONS
    """
}
