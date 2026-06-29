# frozen_string_literal: true

require "rspec/core/rake_task"
require "cucumber/rake/task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features)
RuboCop::RakeTask.new(:rubocop)

desc "Check for vulnerable gems"
task :audit do
  require "bundler/audit/cli"
  Bundler::Audit::Database.update!(quiet: true)
rescue ArgumentError => e
  warn "Warning: bundler-audit database update skipped (#{e.message})"
ensure
  Bundler::Audit::CLI.start(["check"])
end

desc "Check for code duplication with jscpd"
task :duplication do
  unless system("pnpm --version", out: File::NULL, err: File::NULL)
    warn "pnpm not available, skipping duplication check"
    next
  end
  sh "pnpm install --frozen-lockfile 2>/dev/null && pnpm run duplication"
end

desc "Run all static analysis"
task lint: %i[rubocop audit duplication]

desc "Run all verification (spec, features, lint)"
task verify: %i[spec features lint]

task default: :verify

require "rake/gem/maintenance/install_tasks"
