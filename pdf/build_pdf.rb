#!/usr/bin/env ruby

# include Javascript using template_base.xml into template.xml

templ_base_in = open 'template_base.xml', 'rb' do |f|
	f.read
end

js = ""
js += File.read 'LICENSE_jsbn.txt'
js += File.read 'jsbn.js'
js += File.read 'base64.js'
js += File.read 'prng4.js'
js += File.read 'rng.js'
js += File.read 'rsa.js'
js += File.read 'payload.js'

File.open 'template.xml', 'w' do |f|
	f.print templ_base_in.sub('<![CDATA[', "<![CDATA[\n#{js}")
end

# include template into tmp.pdf
#
templ_in = open 'template.xml', 'rb' do |f|
	f.read
end
templ_size = File.size 'template.xml'

pdf_in = open 'base.pdf', 'rb' do |f|
	f.read
end



open 'tmp.pdf', 'w' do |f|
	f.print pdf_in.sub("9 0 obj\nendobj", "9 0 obj\n<</Length #{templ_size}>>stream\n#{templ_in}endstream\nendobj")
end

# add XREF table to final PDF file
system("./pdf_add_xref_table.rb tmp.pdf cryptofax.pdf")

# cleanup
File.unlink 'tmp.pdf'
File.unlink 'template.xml'
