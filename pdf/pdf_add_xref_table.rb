#!/usr/bin/env ruby

# take a handcrafted PDF without xref table and add one before the trailer
require 'pp'

input_file  = ARGV[0]
output_file = ARGV[1]

if ! input_file then
    STDERR.puts "Usage: #{$0} input.pdf [output.pdf]"
    exit 1
end

input = begin
    File.open input_file, 'rb' do |f|
        f.read
    end
rescue
    STDERR.puts "Could not read input file: #{$!}"
    exit 2
end

offset = 0
i = 1
offsets = []

while offset do
    offset = input.index("#{i} 0 obj")
    offsets << offset if offset
    i += 1
end

xref = "xref\n0 #{offsets.size + 1}\n0000000000 65535 f\r\n"
offsets.each do |o|
    xref += "%010d %05d n\r\n" % [ o, 0 ]
end

out = STDOUT
if output_file then
    out = begin
        File.open(output_file, 'w')
    rescue
        STDERR.puts "Could not open output file: #{$!}"
    end
end

output = input.sub('trailer', "#{xref}trailer")
xref_index = output.index("xref\n")
output.sub!('%%EOF', "startxref\n#{xref_index}\n%%EOF")

out.print output
