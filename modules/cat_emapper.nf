process CAT_EMAPPER {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(emappers)
    val(header_length)
    val(comment)

    output:
    tuple val(meta), path("*.annotations"), emit: merged_annotation
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    head -n ${header_length} ${emappers[0]} > header.txt
    cat ${emappers} > ${prefix}.emapper.annotations

    sed -i '/^${comment}/d' ${prefix}.emapper.annotations
    cat header.txt | cat - ${prefix}.emapper.annotations > temp && mv temp ${prefix}.emapper.annotations

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """
}