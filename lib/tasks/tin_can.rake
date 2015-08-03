namespace 'tin_can' do
  require 'tin_can'

  desc 'Start the tin-can handler'
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

  desc 'Stop the daemon'
  task stop: :environment do

  end
end
