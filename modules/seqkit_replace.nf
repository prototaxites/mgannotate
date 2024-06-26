// modified nf-core module
process SEQKIT_REPLACE {
    tag "$meta.assemblyid"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0':
        'biocontainers/seqkit:2.1.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.assemblyid}"
    """
    seqkit \\
        replace \\
        ${args} \\
        --threads ${task.cpus} \\
        -i ${fasta} \\
        -o ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit | sed '3!d; s/Version: //' )
    END_VERSIONS
    """
}