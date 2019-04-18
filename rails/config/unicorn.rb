app_dir = "/app"

working_directory app_dir

listen "/tmp/unicorn.sock", :backlog => 64
pid    "/tmp/unicorn.pid"

worker_processes 1
timeout          30

stdout_path "/dev/stdout"
stderr_path "/dev/stderr"

