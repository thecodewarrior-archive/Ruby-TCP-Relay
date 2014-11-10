#!/usr/bin/env ruby

require_relative 'TCPRelayLib.rb'

mm = TCPRelayMiddleman.new('localhost',9010,8010)

sock   = TCPRelaySocket.new(mm,'foobarbaz')
#sock   = TCPSocket.new('localhost',7777)


begin
  loop do
    v = gets.chomp
    if v =~ /LNG(\d+)/
      v = "12" * ($1.to_i/2)
    end
    sock.puts v
    r = sock.gets.chomp
    puts "Server<#{r.length}>: " + r
  end
ensure
  sock.close
end
