module ProcessRunner
  class ForkPipes
    class Pipe
      attr_reader :read, :write

      def initialize
        @read, @write = IO.pipe
      end

      def read_and_close
        return @data if @data
        write.close
        @data = read.read
        read.close
        @data
      end
    end

    attr_reader :out, :err, :result, :exception

    def initialize
      @out = Pipe.new
      @err = Pipe.new
      @result = Pipe.new
      @exception = Pipe.new
    end

    def close_read
      [@out, @err, @result, @exception].each { |pipe| pipe.read.close }
    end
  end
end
