module JsonRPC
  module Configuration

    attr_writer :connection

    def connection
      @connection || :ssl
    end

    attr_writer :expiration_timeout

    def expiration_timeout
      20 # seconds
    end


    def config
      yield self
    end

  end
end