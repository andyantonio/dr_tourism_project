library(taskscheduleR)

# Schedule to run every 3 months
taskscheduler_create(
  taskname = "run_my_script_every_3_months",
  rscript = "C:/Path/To/my_script.R",
  schedule = "MONTHLY",
  starttime = "00:00",
  startdate = format(Sys.Date(), "%m/%d/%Y"),
  modifier = 3 # every 3 months
)