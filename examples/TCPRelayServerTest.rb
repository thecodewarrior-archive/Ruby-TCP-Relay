#!/usr/bin/env ruby

require_relative 'TCPRelayLib.rb'

mm = TCPRelayMiddleman.new('localhost',9010,8010)

server = TCPRelayServer.new(mm,'foobarbaz', true)
#server = TCPServer.new(7777)
begin
  loop do
    s = server.accept
    l = ""
    puts "opened"
    while (!s.eof?) && ( (l = s.gets.chomp) != "STOP" )
      s.puts l
    end
    puts "closed"
  end
ensure
  server.stop
end
