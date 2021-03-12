# frozen_string_literal: true

class TemporaryDB
  PG_TEMP_PATH = "/tmp/pg_schema_tmp"
  PG_CONF = "#{PG_TEMP_PATH}/postgresql.conf"
  PG_SOCK_PATH = "#{PG_TEMP_PATH}/sockets"

  def port_available?(port)
    TCPServer.open(port).close
    true
  rescue Errno::EADDRINUSE
    false
  end

  def pg_bin_path
    return @pg_bin_path if @pg_bin_path

    ["13", "12", "11", "10"].each do |v|
      bin_path = "/usr/lib/postgresql/#{v}/bin"
      if File.exist?("#{bin_path}/pg_ctl")
        @pg_bin_path = bin_path
        break
      end
    end
    if !@pg_bin_path
      bin_path = "/Applications/Postgres.app/Contents/Versions/latest/bin"
      if File.exists?("#{bin_path}/pg_ctl")
        @pg_bin_path = bin_path
      end
    end
    if !@pg_bin_path
      puts "Can not find postgres bin path"
      exit 1
    end
    @pg_bin_path
  end

  def initdb_path
    return @initdb_path if @initdb_path

    @initdb_path = `which initdb 2> /dev/null`.strip
    if @initdb_path.length == 0
      @initdb_path = "#{pg_bin_path}/initdb"
    end

    @initdb_path
  end

  def find_free_port(range)
    range.each do |port|
      return port if port_available?(port)
    end
  end

  def pg_port
    @pg_port ||= find_free_port(11000..11900)
  end

  def pg_ctl_path
    return @pg_ctl_path if @pg_ctl_path

    @pg_ctl_path = `which pg_ctl 2> /dev/null`.strip
    if @pg_ctl_path.length == 0
      @pg_ctl_path = "#{pg_bin_path}/pg_ctl"
    end

    @pg_ctl_path
  end

  def start
    FileUtils.rm_rf PG_TEMP_PATH
    `#{initdb_path} -D '#{PG_TEMP_PATH}' --auth-host=trust --locale=en_US.UTF-8 -E UTF8 2> /dev/null`

    FileUtils.mkdir PG_SOCK_PATH
    conf = File.read(PG_CONF)
    File.write(PG_CONF, conf + "\nport = #{pg_port}\nunix_socket_directories = '#{PG_SOCK_PATH}'")

    puts "Starting postgres on port: #{pg_port}"
    ENV['DISCOURSE_PG_PORT'] = pg_port.to_s

    Thread.new do
      `#{pg_ctl_path} -D '#{PG_TEMP_PATH}' start`
    end

    puts "Waiting for PG server to start..."
    while !`#{pg_ctl_path} -D '#{PG_TEMP_PATH}' status`.include?('server is running')
      sleep 0.1
    end

    `createuser -h localhost -p #{pg_port} -s -D -w discourse 2> /dev/null`
    `createdb -h localhost -p #{pg_port} discourse`

    puts "PG server is ready and DB is loaded"
  end

  def stop
    `#{pg_ctl_path} -D '#{PG_TEMP_PATH}' stop`
  end

end
