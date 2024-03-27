process SED_FASTA_HEADER {
    tag "${meta.assemblyid}"
    label "process_single"

    input: 
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.renamed.fasta"), emit: fasta
    path "versions.yml"                     , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def sed_arg = task.ext.sed_arg ?: "${meta.id}"
    """
    sed s/^>/>${sed_arg}_/g ${fasta} > ${prefix}.renamed.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(echo \$(sed --version 2>&1) | sed -n '1p' | sed 's/^sed (GNU sed) //')
    END_VERSIONS
    """
}