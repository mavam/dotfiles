#
# Generel
#

# Needed for the dot2texi package which invokes GraphViz.
$latex = 'latex --shell-escape';
$pdflatex = 'pdflatex --shell-escape';

# 
# Mac OS
#
$pdf_previewer = "open -a Skim";
$clean_ext = "paux lox pdfsync out";

#
# Linux
#
#$dvi_previewer = 'start xdvi -geometry 600x600 -watchfile 1';
#$pdf_previewer = "start xpdf -remote localhost";
#$pdf_update_method = 4;
#$pdf_update_command = "xpdf -remote localhost -reload";
