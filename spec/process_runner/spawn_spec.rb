module ProcessRunner
  RSpec.describe Spawn do
    subject(:pool) { Pool.new }

    let(:success) { success = pool.spawn("echo works") }
    let(:failure) { failure = pool.spawn("rm doesnotexist", raise_on_exit_code: false) }

    after(:each) do
      pool.shutdown
      pool.wait_for_termination
    end

    it "captures output" do
      expect(success.stdout).to eq("works\n")
      expect(failure.stderr).to eq("rm: doesnotexist: No such file or directory\n")
    end

    it "captures errors" do
      expect(failure.error).to be_a(Spawn::ProcessFailed)
      expect(failure.error.message).to eq("rm doesnotexist\nfailed with exit code 1\n#{failure.stderr}")
    end

    it "accepts input" do
      expect(pool.spawn("sed 's/hi/bye/'", input: "hi").stdout).to eq("bye\n")
    end

    context "on unexpected exit codes" do
      it "raises on nonzero by default" do
        failure = pool.spawn("diff Gemfile Gemfile.lock")
        expect { failure.wait }.to raise_error(Spawn::ProcessFailed)
      end

      it "accepts expected exit codes" do
        failure = pool.spawn("diff Gemfile Gemfile.lock", expected_exit_codes: [0, 1])
        expect { failure.wait }.to_not raise_error
      end
    end

    it "chains promises" do
      specs = pool.spawn("find . -name '*.rb'").then do |spawn|
        spawn.stdout.split("\n").select { |name| name =~ %r(/spec/) }
      end.wait
      expect(specs.result).to all(match(/spec/))
      expect(specs.result).to all(end_with(".rb"))
    end

    it "rescues promises" do
      expect do
        pool.spawn("rm doesnotexist").rescue do |error|
          expect(error).to be_a(Spawn::ProcessFailed)
        end.wait
      end.to_not raise_error
    end

    it "returns results from rescued promises" do
      rescued = pool.spawn("rm doesnotexist").rescue { "no problem" }.wait
      expect(rescued.result).to eq("no problem")
    end

    it "rescues chained promises" do
      rescued = pool.spawn("ls").then do |spawn|
        raise "error"
      end.rescue do |error|
        "no problem"
      end.wait
      expect(rescued.result).to eq("no problem")
    end

    it "can chain spawns" do
      chained = pool.spawn("find . -name '*.rb'").spawn("grep spec").wait
      expect(chained.stdout.split("\n")).to all(match(/spec/))
    end

    it "can chain with custom input" do
      chained = pool.spawn("find . -name '*.rb'").spawn("grep spec", input: "spectacular").wait
      expect(chained.stdout).to eq("spectacular\n")
    end
  end
end
