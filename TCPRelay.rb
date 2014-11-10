#!/usr/bin/env ruby
require 'socket'
require 'resolv'

$verbose = 0

if !!ARGV.delete('-q')
  $verbose = -1
else
  5.downto(1) do |v|
    if !!ARGV.delete("-#{'v'*v}")
      $verbose = v
      break
    end
  end
end
  

CLIENTPORT = (ARGV[1] || 9010).to_i
SERVERPORT = (ARGV[2] || 8010).to_i

module TCPRelay
  class << self
    @@s = []
    @@c = {}
    @@running = true
=begin
####################################========####################################
####################################--MAIN--####################################
####################################========####################################
=end

    def start()
      debug 0, "Starting..."
      @@server=TCPServer.new SERVERPORT
      @@client=TCPServer.new CLIENTPORT
    
      thr_server = startserver
      thr_client = startclient
      sleep 0.15
      debug 0, "Running..."
      begin
        sleep 1 while true
      rescue Interrupt
        debug 0, "Stopping..."
        thr_server.kill
        thr_client.kill
      end
    end
  
    def startserver
      Thread.new do
        debug "Starting server thread"
        loop do
        	Thread.new(@@server.accept) do |s|
            # accept new connection
        		s.puts "SERVER"
            debug 2, "Recived server connection"
            
            action = s.gets.chomp.upcase
            case action
          
            when "RESERVE"
              # Reserve a name
              debug 3, "RESERVE request"
              name = s.gets.chomp
              if @@s.include?(name)
                debug 3, "RESERVE request failed: USED"
                s.puts "USED"
              else
                @@s << name
              end
              s.close
            
            when "RELEASE"
              # Relese a reservation
              debug 3, "RELEASE request"
              name = s.gets.chomp
              @@s.delete(name)
              s.close
            
            when "CONNECT"
              # Create a connection
              debug 3, "CONNECT request"
              name = s.gets.chomp
              debug 4, "@@s was #{@@s}"
              @@s << name if !@@s.include?(name)
              debug 4, "@@s is now #{@@s}"
              @@c[name] ||= []
              @@c[name] << s
          
            when "STOP"
              s.close
              
            else
              s.puts "UNKNOWN COMMAND"
              s.close
            end
        	end
        end
      end
    end
  
    def startclient
      Thread.new do
        sleep 0.1 if debug? # so debug messages don't conflict
        debug "Starting client thread"
        loop do
        	Thread.new(@@client.accept) do |s|
            # accept new connection
            s.puts "CLIENT"
            debug 2, "Recived client connection"
            channel = s.gets.chomp
            debug 3, "Does channel '#{channel}' exist?"
            debug 3,  "#{
                         @@s.include?(channel) &&
                         @@c.has_key?(channel) &&
                         @@c[channel].length > 0
                        }"
                        
            if @@s.include?(channel)
              debug 4, "Channel '#{channel}' exists, does it have an active connection?"
              if @@c.has_key?(channel) && @@c[channel].length > 0
                debug 4, "Channel '#{channel}' is ready for a connection"
                ss = @@c[channel].pop
                debug 4, "Connecting sockets"
                forward([s,ss])
                debug 4, "Connected sockets"
              else
                debug 4, "Server is offline"
                s.puts "OFFLINE"
              end
            else
              s.puts "NOEXIST"
            end
          end
        end
      end
    end

=begin
####################################========####################################
####################################--MAIN--####################################
####################################========####################################
=end

    def d(*a)
      if a.length == 1
        # if a is just a object, level defaults to one
        l = 1
        o = a[0]
      else
        # if a has more than one value then first value is the level, and the 2nd is the object to print
        l = a[0].to_i
        o = a[1]
      end
      if $verbose >= l
        # if current verbosity level is greater than or equal to print level, print
        warn o
      end
    end

    def d?(l = 1)
      return $verbose >= l
    end

    alias_method :debug, :d
    alias_method :debug?, :d?
    
    def forwardto(i,o)
      # Forward all input from i to o
      if d? 2
        i_port, i_ip = Socket.unpack_sockaddr_in(i.getpeername)
        o_port, o_ip = Socket.unpack_sockaddr_in(o.getpeername)
      end
      debug 2, "Forwarding all input from #{i_ip}:#{i_port} => #{o_ip}:#{o_port}"
    	Thread.new do
        debug 5, "Forward thread started"
    		until i.eof?
          # loop until the socket is closed
    			o.write i.readpartial(2048)
    		end
    		o.close
    	end
    end

    def forward(a)
      # forward both ways between a[0] and a[1]
      debug 2, "calling forwardto twice"
    	forwardto(a[0],a[1])
      a[1].puts "CONNECTED"
    	forwardto(a[1],a[0])
      a[0].puts "CONNECTED"
    end
  end
end

TCPRelay.start

__END__

def start_connection?(k,s)
	start = false
	if $c.has_key?(k) && $c[k].length == 1
		start=:connect
	elsif $c.has_key?(k)
		start=:used
		s.puts "USED"
	else
		start=:new
		s.puts "REGESTER"
	end
	return start
end
