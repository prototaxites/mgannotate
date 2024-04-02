process COVERM_CONTIGS {
    tag "${meta.assemblyid}"
    label "process_medium"

    conda "bioconda::coverm=0.7.0-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coverm:0.7.0--h07ea13f_0' :
        'quay.io/biocontainers/coverm:0.7.0--h07ea13f_0' }"
    
    input:
    tuple val(meta), path(bam), path(reference)

    output:
    tuple val(meta), path("*.txt"), emit: coverage
    path "versions.yml"           , emit: versions
    
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ref = reference.replace("\\.r.*", "")
    """
    TMPDIR=.

    coverm contigs \\
        --threads ${task.cpus} \\
        --reference ${ref} \\
        ${args} \\ 
        --output-file ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strobealign: \$(strobealign --version)
    END_VERSIONS
    """
}
