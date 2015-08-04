require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
namespace 'tin_can' do
  task start: :environment do
    options = {
    app_name: 'tin-can',
    multiple: false,
    backtrace: true,
    monitor: true,
    dir_mode: :script,
    dir: 'tmp/pids/',
    log_output: true,
    log_dir: 'log/',
    output_logfilename: 'tin-can.log',
    }
    Daemons.run_proc('tin-can', options) do
      TinCan.start
    end
  end
end
