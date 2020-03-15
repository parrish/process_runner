module ProcessRunner
  RSpec.describe Fork do
    subject(:pool) { Pool.new }

    after(:each) do
      pool.shutdown
      pool.wait_for_termination
    end

    it "captures output" do
      forks = 3.times.map do |i|
        pool.fork do
          puts "#{i}out"
          $stderr.puts "#{i}err"
          "#{i}result"
        end
      end

      forks.each.with_index do |fork, i|
        fork.wait
        expect(fork.stdout).to eq("#{i}out\n")
        expect(fork.stderr).to eq("#{i}err\n")
        expect(fork.result).to eq("#{i}result")
      end
    end

    it "captures exceptions" do
      fork = pool.fork { raise "error" }
      expect(fork).to receive(:raise) do |e|
        expect(e).to be_a(RuntimeError)
        expect(e.message).to eq("error")
      end
      fork.wait
    end

    it "chains promises" do
      fork = pool.fork { 1 }.then { |i| i + 1 }.then { |i| i + 1 }
      expect(fork.result).to eq(3)
    end

    it "rescues promises" do
      fork = pool.fork { raise "error" }.rescue do |reason|
        expect(reason).to be_a(RuntimeError)
        expect(reason.message).to eq("error")
        123
      end
      expect(fork.result).to eq(123)
    end

    it "raises unrescued exceptions" do
      fork = pool.fork { raise "error" }
      expect { fork.result }.to raise_error("error")
    end

    it "doesn't raise unrescued exceptions when disabled" do
      fork = pool.fork(raise_unrescued: false) { raise "error" }
      expect { fork.result }.to_not raise_error
    end

    it "rescues chained promises" do
      fork = pool.fork { 123 }.then { raise "error" }.rescue do |reason|
        expect(reason).to be_a(RuntimeError)
        expect(reason.message).to eq("error")
        456
      end
      expect(fork.result).to eq(456)
    end
  end
end
