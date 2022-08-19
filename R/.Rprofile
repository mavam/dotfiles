options(repos = c(CRAN = "https://cloud.r-project.org"))

# Use pacman to make sure a few packages exist.
library(utils)
if (!require("pacman"))
  install.packages("pacman", dependencies = TRUE)
pacman::p_load(prettycode, prompt, rdoc, languageserver)
pacman::p_load_gh("jalvesaq/colorout")

# Make for a more convenient REPL experience.
if (interactive()) {
  base::library("colorout")
  base::library("utils")
  rdoc::use_rdoc()
  prompt::set_prompt(prompt::prompt_fancy)
  prettycode::prettycode()
}
