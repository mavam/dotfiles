set -l bin ~/code/tenzir/mono/engine/build/*/release/bin
if test -n "$bin[1]" -a -d "$bin[1]"
    fish_add_path -g $bin
end
