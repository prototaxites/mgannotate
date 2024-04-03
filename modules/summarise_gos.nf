process SUMMARISE_GOS {
    label "process_medium"

    conda "conda-forge::r-base=4.3.2 conda-forge::r-tidyverse=2.0.0"
    container "docker://rocker/tidyverse:4.3.2"

    input:
    path(gos)
    path(go_list)

    output:
    path("GO_df_long.csv")

    script:
    def prefix = params.cluster_genes ? "${cluster_id}_" : ""
    """
    #!/usr/bin/env Rscript

    library(tidyverse)

    gos <- read_csv("${go_list}") |>
        select(GO = id, lbl)

    go_files <- list.files(pattern = "*.GOSummary.csv", full.names = FALSE)

    go_by_sample <- map(go_files, read_csv) |> 
        list_rbind() |>
        left_join(gos)

    write_csv(go_by_sample, "${prefix}GO_df_long.csv")
    """
}