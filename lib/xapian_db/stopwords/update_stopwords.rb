require "fileutils"

LANGUAGE_MAP = {:danish     => :da,
                :dutch      => :nl,
                :english    => :en,
                :finnish    => :fi,
                :french     => :fr,
                :german     => :de,
                :hungarian  => :hu,
                :italian    => :it,
                :norwegian  => :no,
                :portuguese => :pt,
                :russian    => :ru,
                :spanish    => :es,
                :swedish    => :sv}

# 1. Load the stop words files from snowball.tartarus.org
LANGUAGE_MAP.keys.reject{|k| k == :russian}.each { |l| system("curl http://snowball.tartarus.org/algorithms/%s/stop.txt | iconv -f ISO-8859-1 -t UTF-8 > %s.txt" % [l, l]) }
system("curl http://snowball.tartarus.org/algorithms/russian/stop.txt | iconv -f KOI8-R -t UTF-8 > russian.txt")

# 2. Clean up the files (remove comments) and write a new file with the iso name
LANGUAGE_MAP.keys.each do |lang|
  open("#{LANGUAGE_MAP[lang]}.txt", "w") do |outfile|
    open("#{lang}.txt", "r") do |infile|
      while line = infile.gets
        outfile.puts line.split(" ", 2).first.downcase.strip  unless line =~ /^ +|^$|^\|/
      end
    end
  end
end

# 3. Remove the downloaded files
LANGUAGE_MAP.keys.each {|lang| FileUtils.rm_rf "#{lang}.txt"}


