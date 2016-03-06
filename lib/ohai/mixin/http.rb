#
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module ::Ohai::Mixin::Http
  require "socket"

  #
  # attempts to open a socket connection to an address / port
  #
  # @example attempt to open a socket to 172.16.1.15:8080 with a 4 second timeout
  #   can_connect?('172.16.1.15', 8080, 4)
  #
  # @param [String] addr
  #   The address to connect to
  # @param [Integer] port
  #   The port to connect to
  # @param [Integer] timeout
  #   The maximum time to wait in seconds before timing out
  #
  # @return [true, false]
  #
  def can_connect?(addr, port, timeout = 2)
    t = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
    begin
      saddr = Socket.pack_sockaddr_in(port, addr)
    rescue SocketError => e # occurs when the domain doesn't resolve + probably other issues
      Ohai::Log.debug("http mixin: can_connect? failed setting up socket: #{e}")
      return false
    end
    connected = false

    begin
      t.connect_nonblock(saddr)
    rescue Errno::EINPROGRESS
      r, w, e = IO.select(nil, [t], nil, timeout)
      if !w.nil?
        connected = true
      else
        begin
          t.connect_nonblock(saddr)
        rescue Errno::EISCONN
          t.close
          connected = true
        rescue SystemCallError
        end
      end
    rescue SystemCallError
    end
    Ohai::Log.debug("http mixin: test connection to #{addr} on port #{port} #{connected ? 'suceeded' : 'failed'}")
    connected
  end

  module_function :can_connect?

end
