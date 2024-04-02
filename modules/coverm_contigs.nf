process COVERM_CONTIGS {
    tag "${meta.assemblyid}"
    label "process_medium"

    conda "bioconda::coverm=0.7.0-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coverm:0.7.0--h07ea13f_0' :
        'quay.io/biocontainers/coverm:0.7.0--h07ea13f_0' }"
    
    input:
    tuple val(meta), path(reads), path(reference)

    output:
    tuple val(meta), path("*.txt"), emit: coverage
    path "versions.yml"           , emit: versions
    
    script:
    def args   = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    if(meta.single_end) {
        """
        TMPDIR=.
        REF=${reference}

        coverm contig \\
            --threads ${task.cpus} \\
            --single ${reads} \\
            --reference \${REF/%.r*.sti} \\
            ${args} \\ 
            --output-file ${prefix}.txt

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            strobealign: \$(strobealign --version)
        END_VERSIONS
        """
    } else {
        """
        TMPDIR=.
        REF=${reference}

        coverm contig \\
            --threads ${task.cpus} \\
            -1 ${reads[0]} -2 ${reads[1]} \\
            --reference \${REF/%.r*.sti} \\
            ${args} \\ 
            --output-file ${prefix}.txt

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            strobealign: \$(strobealign --version)
        END_VERSIONS
        """
    }
}
