require "process_runner/promised_process"
require "process_runner/fork_pipes"

module ProcessRunner
  class Fork
    include PromisedProcess

    def initialize(pool:, raise_unrescued:, &block)
      @raise_unrescued = raise_unrescued
      @pool = pool.thread_pool
      @block = block
      @promise = Concurrent::Promise.new(executor: @pool)
      run
    end

    def _run(action)
      block = @block
      @promise = @promise.send(action) do |*args|
        pipes = ForkPipes.new

        pid = Process.fork do
          _capture_output do
            pipes.close_read

            begin
              result = block.call(*args)
              Marshal.dump(result, pipes.result.write)
            rescue Exception => e
              Marshal.dump(e, pipes.exception.write)
            end

            pipes.out.write.write($stdout.string)
            pipes.err.write.write($stderr.string)
          end
        end

        _, status = Process.waitpid2(pid)
        _capture_pipes(pipes)
        @result
      end.execute

      self
    end

    def _capture_pipes(pipes)
      @stdout = [@stdout, pipes.out.read_and_close].compact.join("\n")
      @stderr = [@stderr, pipes.err.read_and_close].compact.join("\n")

      @result = pipes.result.read_and_close
      @result = Marshal.load(@result) unless @result.empty?

      exception = pipes.exception.read_and_close
      raise Marshal.load(exception) unless exception.empty?
    end

    def _capture_output(&block)
      out_before = $stdout
      err_before = $stderr

      $stdout = StringIO.new
      $stderr = StringIO.new

      block.call
    ensure
      $stdout = out_before
      $stderr = err_before
    end
  end
end
