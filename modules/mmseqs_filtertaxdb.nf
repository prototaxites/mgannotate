process MMSEQS_FILTERTAXDB {
    tag "${meta.assemblyid}"
    label 'process_medium'

    conda "bioconda::mmseqs2=14.7e284"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mmseqs2:14.7e284--pl5321h6a68c12_2':
        'biocontainers/mmseqs2:14.7e284--pl5321h6a68c12_2' }"

    input:
    tuple val(meta), path(mmseqs_query_tax_db)
    tuple val(db_meta), path(mmseqs_seqtaxdb)

    output:
    tuple val(meta), path("retained_ids") , emit: database
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}/

    mmseqs filtertaxdb \\
        ${mmseqs_seqtaxdb}/${db_meta.basename} \\
        ${mmseqs_query_tax_db}/${meta.basename} \\
        ${prefix}/${prefix} \\
        ${args} \\
        --threads ${task.cpus} \\
        --compressed 0 \\

    awk '\$3 != 1 {print}' ${prefix}/${prefix}.index > retained_ids

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs | grep 'Version' | sed 's/MMseqs2 Version: //')
    END_VERSIONS
    """
}
