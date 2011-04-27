#!/usr/bin/env ruby

# takes mail on STDIN (using .forward), parses the mail to get the PDF attachment,
# decodes the QR code using zbarimg and decrypts the RSA-encrypted content

require 'rubygems'
require 'mail'
require 'tempfile'
require 'base64'
require 'openssl'
require 'twitter'

config = YAML.load(File.open(File.join(File.expand_path('~'),
                             '.cryptofax2tweet.cfg')))

# get mail from STDIN
mail_content = STDIN.read

m = Mail.new(mail_content)
m.attachments.each do |att|
	if att.has_content_type? && att.content_type[/application\/pdf/] then
		t = Tempfile.new 'pdf'
		t.print att.decoded
		t.close
		t2 = Tempfile.new 'png'
		converted = `#{config['convert']} #{t.path} png:#{t2.path}`
		# QR code decode
		decoded = `#{config['zbarimg']} --raw #{t2.path} 2>/dev/null`
		if decoded == '' then
			STDERR.puts "could not decode QR code"
			exit 1
		end
		# base 64 decode
		decoded = Base64.decode64(decoded)

		# decrypt
		key = OpenSSL::PKey::RSA.new(File.read(config['key_location']))
		decrypted = key.private_decrypt decoded

		Twitter.configure do |tw_config|
			tw_config.consumer_key       = config['consumer_key']
			tw_config.consumer_secret    = config['consumer_secret']
			tw_config.oauth_token        = config['oauth_token']
			tw_config.oauth_token_secret = config['oauth_token_secret']
		end

		Twitter.update(decrypted)
		t2.close
		t2.unlink
		t.unlink
	end
end
