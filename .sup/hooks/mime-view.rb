sink = "~/Downloads/#{File.split(filename).last}".gsub(' ', '_')

reverse_cmd = "cat - > #{sink} && qlmanage -p #{sink} &> /dev/null &"
cmd = "cat '#{filename}' | reverse-shell \"#{reverse_cmd}\""

`#{cmd}`
