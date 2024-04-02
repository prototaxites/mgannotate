process COVERM_CONTIGS {
    tag "${meta.assemblyid}"
    label "process_medium"

    conda "bioconda::coverm=0.7.0-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coverm:0.7.0--h07ea13f_0' :
        'quay.io/biocontainers/coverm:0.7.0--h07ea13f_0' }"
    
    input:
    tuple val(meta), path(reads), path(sti), path(fasta)

    output:
    tuple val(meta), path("*.txt"), emit: coverage
    path "versions.yml"           , emit: versions
    
    script:
    def args   = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    if(meta.single_end) {
        """
        TMPDIR=.
        REF=${sti}

        coverm contig \\
            --threads ${task.cpus} \\
            --single ${reads} \\
            --strobealign-use-index \\
            --reference \${REF/%.r*.sti} \\
            ${args} \\
            --output-file ${prefix}.txt

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            coverm: \$(coverm --version | sed 's/coverm //')
        END_VERSIONS
        """
    } else {
        """
        TMPDIR=.
        REF=${sti}

        coverm contig \\
            --threads ${task.cpus} \\
            -1 ${reads[0]} -2 ${reads[1]} \\
            --strobealign-use-index \\
            --reference \${REF/%.r*.sti} \\
            ${args} \\
            --output-file ${prefix}.txt

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            coverm: \$(coverm --version | sed 's/coverm //')
        END_VERSIONS
        """
    }
}
