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
  if (/processes/)
  {
    proc = sprintf("proc %s (%sr %ss)", $1, $3, $5)
  }
  else if (/load averages/)
  {
    split($6, l1, ",")
    split($7, l2, ",")
    load = sprintf("load %s %s %s", l1[1], l2[1], $8)
  }
  else if (/Mem/)
  {
    mem = sprintf("mem %s-active %s-free", $2, $12)
  }
}

END \
{
  print load sep mem sep proc
}
