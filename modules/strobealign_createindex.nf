process STROBEALIGN_CREATEINDEX {
    tag "${meta.assemblyid}"
    label "process_low"

    conda "bioconda::strobealign:0.13.0-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/strobealign:0.13.0--h43eeafb_0':
        'biocontainers/strobealign:0.13.0--h43eeafb_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.sti"), path(fasta), emit: index
    path "versions.yml"                        , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    strobealign \\
        --create-index \\
        -t ${task.cpus} \\
        ${fasta} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strobealign: \$(strobealign --version)
    END_VERSIONS
    """
}