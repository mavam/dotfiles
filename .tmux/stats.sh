#!/bin/sh

top -R -F -l 1 \
  | head -n 9 \
  | awk 'BEGIN { ORS = ""; sep = " | " } \
         { if (/Proc/) \
           { \
             a["proc"] = sprintf("proc %s (%sr %ss %sz %st)", $2, $4, $6, $8, $10) \
           } \
           else if (/Load/) \
           { \
             a["load"] = sprintf("load %s %s %s", substr($3, 0, 4), substr($4, 0, 4), $5) \
           } \
           else if (/CPU/) \
           { \
             a["cpu"] = sprintf("CPU %iu %is", $3, $5) \
           } \
           else if (/Phys/) \
           { \
             a["mem"] = sprintf("mem w:%s a:%s i:%s u:%s f:%s", $2, $4, $6, $8, $10) \
           } \
        } \
        END { print a["load"] sep a["cpu"] sep a["mem"] sep a["proc"] }
       '
