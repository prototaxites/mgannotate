//modified nf-core module
process EGGNOG_MAPPER_DATABASE {
    label 'process_medium'

    conda "bioconda::eggnog-mapper=2.1.12-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper:2.1.12--pyhdfd78af_0':
        'biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0' }"

    output:
    path("${prefix}/")  , emit: database
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: 'eggnog'
    """
    mkdir ${prefix}/

    download_eggnog_data.py  \\
        --data_dir ${prefix} \\
        -y \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog-mapper: \$(echo \$(emapper.py --version) | grep -o "emapper-[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+" | sed "s/emapper-//")
    END_VERSIONS
    """
}