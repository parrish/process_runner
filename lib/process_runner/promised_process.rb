module ProcessRunner
  module PromisedProcess
    def run
      _run(:then)
    end

    def wait
      return self if @waiting
      @waiting = true
      @promise.wait
      @waiting = false
      raise @promise.reason if @promise.rejected? && @raise_unrescued
      self
    end

    def stdout
      wait
      @stdout
    end

    def stderr
      wait
      @stderr
    end

    def result
      wait
      @result
    end

    def then(&block)
      @block = block
      _run(:then)
    end

    def rescue(&block)
      @block = block
      _run(:rescue)
    end
  end
end
