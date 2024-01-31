process GENES_TO_GOS {
    tag "$meta.sampleid"
    label "process_medium"

    conda "conda-forge::r-base=4.3.2 conda-forge::r-tidyverse=2.0.0"
    container "docker://rocker/tidyverse:4.3.2"

    input:
    tuple val(meta), path(counts), path(eggnog), path(cluster_tsv)
    path(go_list)

    output:
    tuple val(meta), path("*.annotations_counts.csv") , emit: annotations_counts
    tuple val(meta), path("*.GOSummary.csv")          , emit: gosummary

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/usr/bin/env Rscript

    library(tidyverse)

    summarise_go <- function(df, go) {
        summary <- filter(df, str_detect(GO, go)) |>
            mutate(GO = go) |>
            summarise(Nreads = sum(Count),
                Ngenes = n(),
                .by = GO)

        if(nrow(summary) == 0) {
            summary <- tibble(GO = go, Nreads = 0, Ngenes = 0)
        }

        return(summary)
    }

    gos <- read_csv("${go_list}")
    counts <- read_tsv("${counts}", col_names = c("gene_name", "Count"))
    clusters <- read_tsv("${cluster_tsv}", col_names = c("query", "gene_name"))
    eggnog <- read_tsv("${eggnog}", 
        comment = "#", 
        col_names = c("query", "seed_ortholog",	"evalue", "score", "eggNOG_OGs",
            "max_annot_lvl", "COG_category", "Description", "Preferred_name", "GO",
            "EC", "KEGG_ko", "KEGG_Pathway", "KEGG_Module",
            "KEGG_Reaction", "KEGG_rclass",	"BRITE", "KEGG_TC",	"CAZy",	"BiGG_Reaction", "PFAMs"))

    clusters <- rowwise(clusters) |> 
        mutate(gene_name = paste(str_split_i(query, "\\\\|", 1), 
            str_split_i(query, "\\\\|", 2), 
            str_split_i(query, "\\\\|", 3),
            str_split_i(query, "\\\\|", 7), 
            sep = "|")
        )

    df <- counts |>
        left_join(clusters) |>
        left_join(eggnog)

    unmapped <- df |>
        filter(str_detect(gene_name, "^__")) |>
        mutate(GO = "Unmapped") |>
        summarise(Nreads = sum(Count),
            Ngenes = NA,
            .by = GO) 

    unannotated <- df |>
        filter(is.na(GO), !str_detect(gene_name, "^__")) |>
        mutate(GO = "Unannotated") |>
        summarise(Nreads = sum(Count),
            Ngenes = n(),
            .by = GO)

    go_list <- pull(gos, id)
    go_counts <- map(go_list, \\(x) summarise_go(df, x)) |>
        list_rbind() |>
        bind_rows(unannotated) |>
        bind_rows(unmapped) |>
        mutate(Sample = "${prefix}",
            nreads = ${meta.nreads})

    write_csv(df, "${prefix}.annotations_counts.csv")
    write_csv(go_counts, "${prefix}.GOSummary.csv")
    """
}