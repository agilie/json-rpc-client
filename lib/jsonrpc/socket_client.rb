require "jsonrpc/version"
require 'jsonrpc/socket_client/exceptions'

require 'socket'
require 'json'
require 'openssl'
require 'timeout'

module JsonRPC
  class SocketClient

    def initialize(host, port, options = {connection: JsonRPC.connection})
      @host = host
      @port = port
      @connection = options[:connection]
    end

    def request(method, params, id = make_id)
      socket = client
      socket.write(
          make_json(method, params, id)
      )
      response = nil
      Timeout::timeout(JsonRPC.expiration_timeout) do
        while line = socket.gets
          if line.include?(id.to_s)
            response = JSON.parse(line)
            break
          end
        end
      end
      response
    end

    private

    def client
      if @connection == :tcp
        tcp_client
      elsif @connection == :ssl
        ssl_client
      else
        raise 'Invalid client type'
      end
    end

    def tcp_client
      TCPSocket.open(@host, @port)
    end

    def ssl_client
      socket = TCPSocket.open(@host, @port)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
      ssl_socket.sync_close = true
      ssl_socket.connect
      ssl_socket
    end

    def make_json(method, params, id)
      params = [params] unless params.is_a?(Array)
      json = {
          jsonrpc: '2.0',
          method: method,
          params: params,
          id: id,
      }
      "#{json.to_json}\n"
    end

    def make_id
      Time.now.to_f
    end

  end

end