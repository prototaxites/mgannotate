process COUNT_FASTQ {
    tag "${meta.sampleid}"
    label "process_single"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path(fastq), env(count), emit: fastq

    script:
    """
    count=\$(echo \$(zcat ${fastq[0]} | wc -l) / 4 | bc)
    """
}