process GENES_TO_GOS {
    tag "${meta.sampleid}"
    label "process_medium"

    conda "conda-forge::r-base=4.3.2 conda-forge::r-tidyverse=2.0.0"
    container "docker://rocker/tidyverse:4.3.2"

    input:
    tuple val(meta), path(counts), path(eggnog), path(gff)
    path(go_list)
    val(input_is_clustered)

    output:
    tuple val(meta), path("*.annotations_counts.csv") , emit: annotations_counts
    tuple val(meta), path("*.GOSummary.csv")          , emit: gosummary

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def clustered = input_is_clustered ? "clustered" : "not_clustered"
    def gff_exists = gff ? "gff_exists" : "gff_absent"
    """
    #!/usr/bin/env Rscript

    library(tidyverse)

    summarise_go <- function(df, go) {
        summary <- filter(df, str_detect(GO, go)) |>
            mutate(GO = go) |>
            summarise(Nreads = sum(Count),
                Ngenes = n(),
                genes_length = sum(gene_length),
                .by = GO)

        if(nrow(summary) == 0) {
            summary <- tibble(GO = go, Nreads = 0, Ngenes = 0)
        }

        return(summary)
    }

    clustered <- ifelse("${input_is_clustered}" == "clustered", TRUE, FALSE)
    gos <- read_csv("${go_list}")

    if(clustered == TRUE) {
        counts <- read_tsv("${counts}") |> select(gene_name = 1, Count = 2)
    } else {
        counts <- read_tsv("${counts}", col_names = c("gene_name", "Count"))
    }
    
    eggnog <- read_tsv("${eggnog}", 
        comment = "#", 
        col_names = c("query", "seed_ortholog",	"evalue", "score", "eggNOG_OGs",
            "max_annot_lvl", "COG_category", "Description", "Preferred_name", "GO",
            "EC", "KEGG_ko", "KEGG_Pathway", "KEGG_Module",
            "KEGG_Reaction", "KEGG_rclass",	"BRITE", "KEGG_TC",	"CAZy",	"BiGG_Reaction", "PFAMs")
    )

    if(clustered == TRUE) {
        eggnog <- rowwise(eggnog) |>
        mutate(split_q = str_split(query, "\\\\|"),
            gene_name = paste(split_q[1], split_q[2], split_q[3], split_q[7], sep = "|")
        )
    } else {
        eggnog <- mutate(eggnog, gene_name = query)
    }

    if(${gff_exists} == "gff_exists") {
        gff <- read_tsv("${gff}", 
            col_names = c("seqname", "source", "feature", 
                "start", "end", "score", "strand", "frame", "attribute")
            ) |> 
            filter(feature == "gene") |>
            mutate(gene_name = str_extract(attribute, ".*TCS_ID=(.*)\$", group = 1),
                gene_length = end - start
            )
    }

    if(clustered == TRUE) {
        df <- counts |>
            left_join(eggnog, by = "gene_name") |>
            mutate(gene_length = NA)
    } else {
        df <- counts |>
            left_join(gff, by = "gene_name") |>
            left_join(eggnog, by = "gene_name")
    }

    unmapped <- df |>
        filter(str_detect(gene_name, "^__")) |>
        mutate(GO = "Unmapped") |>
        summarise(Nreads = sum(Count),
            Ngenes = NA,
            genes_length = NA,
            .by = GO) 

    unannotated <- df |>
        filter(is.na(GO), !str_detect(gene_name, "^__")) |>
        mutate(GO = "Unannotated") |>
        summarise(Nreads = sum(Count),
            Ngenes = n(),
            genes_length = sum(gene_length),
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