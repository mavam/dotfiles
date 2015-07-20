BEGIN \
{
  ORS = ""
  sep = " ● "
  proc = ""
  load = ""
  cpu = ""
  mem = ""
}

{
  if (/Proc/)
  {
    proc = sprintf("proc %s (%sr %ss %sz %st)", $2, $4, $6, $8, $10)
  }
  else if (/Load/)
  {
    split($3, l1, ",")
    split($4, l2, ",")
    load = sprintf("load %s %s %s", l1[1], l2[1], $5)
  }
  else if (/CPU/)
  {
    cpu = sprintf("CPU %iu %is", $3, $5)
  }
  else if (/Phys/)
  {
    split($2, used, "M")
    split($6, unused, "M")
    mem = sprintf("mem %sM / %sM", used[1], used[1] + unused[1])
  }
}

END \
{
  print load sep cpu sep mem sep proc
}
