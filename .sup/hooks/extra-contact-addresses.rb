base = '~/Library/Application Support/AddressBook'
file = 'AddressBook-v22.abcddb'
local = File.expand_path("#{base}/#{file}")
remote = Dir.glob(File.expand_path("#{base}/Sources/*/#{file}"))

contacts = []
[local, remote].flatten.each do |ab|
  if File.exists?(ab)
    require 'sqlite3'
    db = SQLite3::Database.new(ab)
    sql = "select e.ZADDRESSNORMALIZED,p.ZFIRSTNAME,p.ZLASTNAME,p.ZORGANIZATION" +
      " from ZABCDRECORD as p,ZABCDEMAILADDRESS as e WHERE e.ZOWNER = p.Z_PK;"
    db.execute(sql).map do |c|
      contacts << if c[1]
        "#{c[1]} #{c[2]} <#{c[0]}>"
      elsif c[3]
        "#{c[3]} <#{c[0]}>"
      else
        c[0]
      end
    end
  end
end

contacts
