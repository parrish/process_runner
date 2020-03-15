module ProcessRunner
  class Pool
    attr_reader :thread_pool

    def initialize(concurrency = Concurrent.processor_count)
      @thread_pool = Concurrent::FixedThreadPool.new(concurrency)
    end

    def fork(raise_unrescued: true, &block)
      Fork.new(pool: self, raise_unrescued: raise_unrescued, &block)
    end

    def spawn(command, input: nil, expected_exit_codes: [0], raise_on_exit_code: true)
      Spawn.new(
        pool: self,
        command: command,
        input: input,
        expected_exit_codes: expected_exit_codes,
        raise_on_exit_code: raise_on_exit_code,
      )
    end

    def shutdown
      @thread_pool.shutdown
    end

    def wait_for_termination
      @thread_pool.wait_for_termination
    end
  end
end
