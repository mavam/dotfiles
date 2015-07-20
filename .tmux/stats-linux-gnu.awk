BEGIN \
{
  load=""
  cpu=""
  mem=""
  proc=""
}

{
  if (/^top/)
  {
    split($12, l1, ",")
    split($13, l2, ",")
    load = sprintf("load %s %s %s", l1[1], l2[1], $14)
  }
  else if (/Tasks/) 
  {
    proc = sprintf("proc %s (%sr %ss %sz)", $2, $4, $6, $10) 
  }
  else if (/Cpu/)
  {
    split($2, u, ".")
    split($3, s, ".")
    cpu = sprintf("cpu %su %ss", u[1], s[1])
  }
  else if (/Mem/)
  {
    split($4, used, "k")
    split($2, total, "k")
    mem = sprintf("mem %sM / %sM", int(used[1] / 1024), int(total[1] / 1024))
  }
}

END \
{
  print load sep cpu sep mem sep proc
}
