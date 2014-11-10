Ruby-TCP-Relay
==============

A relay allowing for TCP connections over NAT/Firewall using a middleman server written in Ruby

The relay works as follows:

Normally, if you have a server _(S)_ behind a NAT/Firewall _(N)_ you _(C)_ can't access it
```
S ---- N <--- N <--- C
     ^ NAT doesn't pass connection from C on to S
```
But by using TCP Relay _(R)_ you can access servers behind anything that allows outgoing connections (all but the strictest firewalls)
```
S ---> N ---> R <--- N <--- C
           ^     ^ both of these are "outgoing" connections, so NAT/Firewall stays happy
```

How it works, is the server registers a name with the relay, 
once the server makes a connection and sends the `CONNECT` message along with a name to the relay, 
the relay stores that connection under that name, now, once a client connects to the relay and asks for that name, 
the relay will "connect" the two sockets. Creating two threads, 
one that reads from the server and writes that data to the client, 
and another that does the opposite, sending data from the client to the server. 

TL;DR;

The client and server both connect "up" to the relay, and once there is a pair, 
they get "plugged into each other" everything from the client gets forwarded to the server, and vice versa.

Example usage:

Server:
```ruby
require 'TCPRelayLib.rb'

mm = TCPRelayMiddleMan.new('localhost',9010,8010)
# (middleman ip/domain, client port, server port) 9010/8010 are default ports.
# server requires only server port, client port can be nil

server = TCPRelayServer.new(mm, 'my_awesome_server_ID', false)
# middleman, server id, already reserved (optional, default false)

sock = server.accept
# sock is a normal tcp socket, do whatever you want with it.
# (except reopen it in any way. then it won't work)

```

Client:
```ruby
require 'TCPRelayLib.rb'

mm = TCPRelayMiddleMan.new('localhost', 9010, 8010)
# (middleman ip/domain, client port, server port) 9010/8010 are default ports.
# client requires only client port, server port can be nil

sock = TCPRelaySocket.new(mm, 'my_awesome_server_ID')
# sock is a normal tcp socket, do whatever you want with it.
# (except reopen it in any way. then it won't work)

```
