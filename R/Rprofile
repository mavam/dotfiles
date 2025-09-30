options(repos = c(CRAN = "https://cloud.r-project.org"))

if (interactive()) {
  if (require("rdoc", quietly = TRUE)) {
    library(utils)
    rdoc::use_rdoc()
  }
  require(colorout, quietly = TRUE)
  if (require(prompt, quietly = TRUE))
    prompt::set_prompt(prompt::prompt_fancy)
  if (require(prettycode, quietly = TRUE))
    prettycode::prettycode()
}
