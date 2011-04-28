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

logtime = Time.new.to_i
DEBUG = false
logfile = 
if DEBUG then
	File.open File.join(File.expand_path('~'), "#{logtime}.log"), 'w'
end

# get mail from STDIN
mail_content = STDIN.read
if DEBUG then
	File.open File.join(File.expand_path('~'), "#{logtime}.mail"), 'w' do |f|
		f.print mail_content
	end
end

m = Mail.new(mail_content)
logfile.puts "Mail object: #{m.inspect}" if DEBUG

m.attachments.each do |att|
	logfile.puts "Mail has attachment: #{att.inspect}" if DEBUG
	if att.has_content_type? && att.content_type[/application\/pdf/] then
		logfile.puts "attachment is PDF" if DEBUG
		t = Tempfile.new 'pdf'
		t.print att.decoded
		t.close
		t2 = Tempfile.new 'png'
		converted = `#{config['convert']} #{t.path} png:#{t2.path}`
		logfile.puts "converted to PNG: #{converted}" if DEBUG
		# QR code decode
		stderr_out = DEBUG ? File.join(File.expand_path('~'), "#{logtime.stderr}") : '/dev/null'

		decoded = `#{config['zbarimg']} --raw #{t2.path} 2>#{stderr_out}`
		if $?.exitstatus != 0 then
			STDERR.puts "could not decode QR code"
			exit 1
		end
		# base 64 decode
		decoded = Base64.decode64(decoded)
		logfile.puts "decoded QR code: #{decoded}" if DEBUG

		# decrypt
		key = OpenSSL::PKey::RSA.new(File.read(config['key_location']))
		decrypted = key.private_decrypt decoded
		logfile.puts "decrypted tweet: #{decrypted}" if DEBUG

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
