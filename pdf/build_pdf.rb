#!/usr/bin/env ruby

pdf_in = open 'base.pdf', 'rb' do |f|
	f.read
end
templ_in = open 'template.xml', 'rb' do |f|
	f.read
end
templ_size = File.size 'template.xml'

open 'tmp.pdf', 'w' do |f|
	f.print pdf_in.sub("9 0 obj\nendobj", "9 0 obj\n<</Length #{templ_size}>>stream\n#{templ_in}endstream\nendobj")
end

system("./pdf_add_xref_table.rb tmp.pdf cryptofax.pdf")
File.unlink 'tmp.pdf'
