#!/usr/bin/env ruby

# takes mail on STDIN (using .forward), parses the mail to get the PDF attachment,
# decodes the QR code using zbarimg and decrypts the RSA-encrypted content

require 'rubygems'
require 'mail'
require 'tempfile'
require 'base64'

# get mail from STDIN

# TODO: use config file (YAML?)
ZBARIMG = "/usr/local/bin/zbarimg"
OPENSSL = "/usr/bin/openssl"
KEY_LOCATION = "/crypthome/alech/devel/nradf/frickl/key.pem"

mail_content = STDIN.read
m = Mail.new(mail_content)
m.attachments.each do |att|
	if att.has_content_type? && att.content_type == 'application/pdf' then
		t = Tempfile.new 'pdf'
		t.print att.decoded
		t.close
		# QR code decode
		decoded = `#{ZBARIMG} --raw #{t.path} 2>/dev/null`
		if decoded == '' then
			STDERR.puts "could not decode QR code"
			exit 1
		end
		# base 64 decode
		decoded = Base64.decode64(decoded)

		# decrypt (TODO: maybe use ruby openssl?)
		t2 = Tempfile.new 'crypt'
		t2.print decoded
		t2.close
		
		decrypted = `#{OPENSSL} rsautl -decrypt -inkey #{KEY_LOCATION} -in #{t2.path}`

		puts decrypted

		# TODO: tweet
	end
end
