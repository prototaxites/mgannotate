process EGGNOG_MAPPER {
    tag "$meta.assemblyid"
    label 'process_medium'

    conda "bioconda::eggnog-mapper=2.1.12-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper:2.1.12--pyhdfd78af_0':
        'biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta), path(gff)
    path(eggnog_dir)

    output:
    tuple val(meta), path("*.emapper.annotations")   , emit: annotations
    tuple val(meta), path("*.xlsx")                  , emit: excel, optional: true
    tuple val(meta), path("*.gff")                   , emit: gff, optional: true
    tuple val(meta), path("*.emapper.seed_orthologs"), emit: orthologs
    tuple val(meta), path("*.emapper.hits")          , emit: hits
    path "versions.yml"                              , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.name.endsWith(".gz")
    def fasta_name = fasta.name.replace(".gz", "")
    def dbmem = task.memory.toMega() > 40000 ? '--dbmem' : ''
    def gff_arg = gff ? "--decorate_gff ${gff}" : ""
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    emapper.py \\
        --cpu ${task.cpus} \\
        -i ${fasta_name} \\
        ${args} \\
        ${gff_arg} \\
        --data_dir ${eggnog_dir} \\
        --output ${prefix} \\
        ${dbmem}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog-mapper: \$(echo \$(emapper.py --version) | grep -o "emapper-[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+" | sed "s/emapper-//")
    END_VERSIONS
    """
}