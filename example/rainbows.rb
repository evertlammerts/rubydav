Rainbows! do
  use :FiberPool # concurrency model to use
  worker_connections 128
  client_max_body_size nil # bytes. nil means no limit.
  keepalive_requests 100 # default:100
  client_header_buffer_size 4 * 1024 # 4 kilobytes
end

#listen 8080 # by default Unicorn listens on port 8080
worker_processes 1 # this should be >= nr_cpus
rewindable_input false
pid "log/unicorn.pid"
stderr_path "log/unicorn.err"
stdout_path "log/unicorn.out"
