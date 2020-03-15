require "open3"
require "process_runner/promised_process"

module ProcessRunner
  class Spawn
    include PromisedProcess

    class ProcessFailed < StandardError
      def initialize(command, exit_code, stderr)
        super("#{command}\nfailed with exit code #{exit_code}\n#{stderr}")
      end
    end

    def initialize(pool:, command:, input: nil, expected_exit_codes: [0], raise_on_exit_code: true)
      @pool = pool
      @expected_exit_codes = expected_exit_codes
      @raise_on_exit_code = raise_on_exit_code
      @raise_unrescued = true
      @promise = Concurrent::Promise.new(executor: @pool.thread_pool)
      @block = _spawn(command, input)
      run
    end

    def error
      wait
      @error
    end

    def successful?
      wait
      !!@error
    end

    def error?
      !successful?
    end

    def spawn(command, input: nil, expected_exit_codes: nil, raise_on_exit_code: nil)
      wait
      @pool.spawn(
        command,
        input: input || stdout,
        expected_exit_codes: expected_exit_codes || @expected_exit_codes,
        raise_on_exit_code: raise_on_exit_code || @raise_on_exit_code,
      )
    end

    def _spawn(command, input)
      Proc.new do
        @stdout, @stderr, status = Open3.capture3(command, stdin_data: input)

        successful = @expected_exit_codes.include?(status.exitstatus)
        unless successful
          @error = ProcessFailed.new(command, status.exitstatus, @stderr)
          raise @error if @raise_on_exit_code
        end
        self
      end
    end

    def _run(action)
      block = @block
      @promise = @promise.send(action) do |*args|
        @result = block.call(*args)
      end.execute
      self
    end
  end
end
