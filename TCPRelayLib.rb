require 'socket'

class TCPRelayServer
  
  def initialize(middleman, name, reserved = false)
    @mmport     = middleman.server_port
    @mmip       = middleman.ip
    @servername = name
    
    puts "server: #{@mmip}:#{@mmport}"
    
    s = TCPSocket.new @mmip, @mmport
    raise MiddlemanPortError if s.gets.chomp.upcase != "SERVER"
    unless reserved
      s.puts "RESERVE"
      s.puts @servername
      v = s.gets
      puts v
      raise TCPRelayNameError if v.chomp.upcase == "USED"
    end
    s.close
  end
  
  def accept
    s = TCPSocket.new @mmip, @mmport
    s.gets # gobble up the "SERVER"
    s.puts "CONNECT"
    s.puts @servername
    puts s.gets # wait for and gobble the "CONNECTED" message
    return s
  end
  
  def stop
    s = TCPSocket.new @mmip, @mmport
    raise MiddlemanPortError if s.gets.chomp.upcase != "SERVER"
    s.puts "RELEASE"
    s.puts @servername
    s.close
  end
  
end

class TCPRelaySocket < TCPSocket
  def initialize(middleman, name)
    @mmport     = middleman.client_port
    @mmip       = middleman.ip
    @servername = name
    
    #puts "client: #{@mmip}:#{@mmport}"
    
    s = super @mmip, @mmport
    raise MiddlemanPortError if s.gets.chomp.upcase != "CLIENT"
    s.puts @servername
    resp = s.gets.chomp.upcase
    raise TCPRelayOfflineError if resp == "OFFLINE"
    raise TCPRelayNoexestError if resp == "NOEXIST"
    return s if resp == "CONNECT"
  end
end

class TCPRelayMiddleman
  
  attr_accessor :ip, :client_port, :server_port
  
  def initialize(ip,port_client,port_server)
    @ip = ip
    @client_port = port_client
    @server_port = port_server
  end
end

class TCPRelayError < StandardError
end

class TCPRelayNameError < TCPRelayError
end

class TCPRelayOfflineError < TCPRelayError
end

class TCPRelayNoexestError < TCPRelayError
end

class MiddlemanError < TCPRelayError
end

class MiddlemanPortError < MiddlemanError
end
