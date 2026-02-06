set -l tenzir_bin ~/code/tenzir/tenzir/build/*/release/bin
if test -n "$tenzir_bin[1]" -a -d "$tenzir_bin[1]"
    fish_add_path -g $tenzir_bin
end
