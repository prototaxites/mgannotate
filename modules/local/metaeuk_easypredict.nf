//modified nf-core module
process METAEUK_EASYPREDICT {
    tag "$meta.assemblyid"
    label 'process_medium'

    conda "bioconda::metaeuk=6.a5d39d9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaeuk:6.a5d39d9--pl5321hf1761c0_2':
        'biocontainers/metaeuk:6.a5d39d9--pl5321hf1761c0_2' }"

    input:
    tuple val(meta), path(contigs)
    tuple val(db_meta), path(database)

    output:
    tuple val(meta), path("${prefix}.fas")      , emit: faa
    tuple val(meta), path("${prefix}.codon.fas"), emit: codon
    tuple val(meta), path("*.tsv")              , emit: tsv
    tuple val(meta), path("*.gff")              , emit: gff
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def input = contigs.isDirectory() ? "${contigs}/${meta.basename}" : "${contigs}"
    """
    metaeuk easy-predict \\
        ${input} \\
        ${database}/${db_meta.basename} \\
        ${prefix} \\
        tmp/ \\
        ${args}

    rm -r tmp/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaeuk: \$(metaeuk | grep 'Version' | sed 's/metaeuk Version: //')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fas
    touch ${prefix}.codon.fas
    touch ${prefix}.headersMap.tsv
    touch ${prefix}.gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaeuk: \$(metaeuk | grep 'Version' | sed 's/metaeuk Version: //')
    END_VERSIONS
    """
}
