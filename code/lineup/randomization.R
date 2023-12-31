substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

num_param_values = 9
param_values_per_participant = 6
rorschach_values_per_participant = 1
num_sets = 2

# Read in picture details ------------------------------------------------------
library(RSQLite)
library(DBI)
sqlite.driver <- dbDriver("SQLite")

filename <- "databases/01_lineups_db.db"

# filename <- "perception-of-statistical-graphics/databases/01_lineups_db.db"
con <- dbConnect(sqlite.driver, dbname = filename)
picture_details_randomization<- dbReadTable(con, "picture_details")
dbDisconnect(con)

picture_details_randomization$set <- rep(c(1,1,2,2),num_param_values) 
picture_details_randomization$rorschach <- substrRight(picture_details_randomization$param_value,1)

# Select param values per participant
param_details <- picture_details_randomization %>%
  filter(rorschach == 0)
unique_param_values <- unique(param_details$param_value)
param_block_ids <- tibble(param_id = sample(1:length(unique_param_values), param_values_per_participant)) %>%
             mutate(param_value = unique_param_values[param_id],
                    set  = sample(1:num_sets,param_values_per_participant, replace = T)) %>%
             expand_grid(test_param = c("linear", "log"))

# Select 1 rorschach combo
rorschach_details <- picture_details_randomization %>%
  filter(rorschach == 1)
unique_rorschach_values <- unique(rorschach_details$param_value)
rorschach_block_ids <- tibble(param_id = sample(1:length(unique_rorschach_values), rorschach_values_per_participant)) %>%
  expand_grid(test_param = c("linear", "log")) %>%
  mutate(param_value = unique_rorschach_values[param_id],
         set  = sample(1:num_sets,rorschach_values_per_participant*2, replace = T))

block_ids <- rbind(param_block_ids, rorschach_block_ids[sample(1:2,1),]) %>%
  mutate(order = sample(1:13, 13, replace = F)) %>%
  arrange(order)

joinCols = c("test_param", "param_value", "set")
picture_details_order <- left_join(block_ids, picture_details_randomization, by = joinCols)
# View(picture_details_order)
