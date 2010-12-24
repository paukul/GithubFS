require 'rubygems'
require 'fusefs'
require 'fileutils'
require 'httparty'
require 'logger'
require 'lib/user'
require 'lib/repository'

class GHFS
  attr_reader :virt_dir
  BLACKLIST = [/mach_kernel/, /\./]
  def initialize
    @real_dir = File.expand_path("~/.ghfs_data")
    @virt_dir = File.join(Dir.pwd, "ghfs")
    [@real_dir, @virt_dir].each do |dir|
      FileUtils.mkdir(dir) unless File.exists?(dir)
    end
    @users = {}
    @repos = {}
  end

  def contents(path)
    logger.debug "contents(#{path}) (#{path_type(path).inspect})"
    case path_type(path)
    when :username
      get_repos(username_from_path(path)).map{|r| r["name"]}
    when :repository
      mkdir(username_from_path(path)) unless directory?(username_from_path(path))
      clone_repo(path) unless directory?(real_path(path))
      Dir[real_path(path) + "/*"].map{|f| File.basename(f)}
    else
      Dir[real_path(path) + "/*"].map{|f| File.basename(f)}
    end
  end

  def file?(path)
    logger.debug "file?(#{path})"
    File.file?(real_path(path))
  end

  def size(path)
    logger.debug "size(#{path})"
    File.size(real_path(path))
  end

  def directory?(path)
    logger.debug "directory?(#{path})"
    case path_type(path)
    when :repository
      get_repos(username_from_path(path)).any? {|r| r["name"] == repository_from_path(path)}
    # when :username
    #   !!get_user(username_from_path(path))
    else
      File.directory?(real_path(path))
    end
  end

  def read_file(path)
    logger.debug "reading #{path} from #{real_path(path)}"
    File.read(real_path(path)) + "\n"
  end

  def can_mkdir?(path)
    logger.debug "can_mkdir?(#{path})"
    path_type(path) == :username && !!get_user(username_from_path(path))
  end

  def mkdir(path)
    logger.debug "mkdir(#{path})"
    FileUtils.mkdir(real_path(path))
  end

  def can_write?(path)
    logger.debug "can_write?(#{path})"
    false
  end

  def can_delete?(path)
    logger.debug "can_delete?(#{path})"
    false
  end

  private
  def get_user(username)
    @users[username] ||= User.find(username)
  end

  def get_repos(username)
    @repos[username] ||= Repository.for_user(username)
  end

  def real_path(path)
    rp = File.join(@real_dir, path)
    logger.debug "Real path: #{rp}"
    rp
  end

  def username_from_path(path)
    path[/^\/(.+?)?(?:\/(.+?))?(?:\/(.+?))?\/?$/, 1]
  end

  def repository_from_path(path)
    path[/^\/(.+?)?(?:\/(.+?))?(?:\/(.+?))?\/?$/, 2]
  end

  def repo_data_from_path(path)
    path[/^\/(.+?)?(?:\/(.+?))?(?:\/(.+?))?\/?$/, 3]
  end

  def path_type(path)
    return :root if path == "/"
    return :other if BLACKLIST.any? {|b| path =~ b}
    levels = path.count("/")
    levels -= 1 if path[/.$/] == "/"
    case levels
    when 1
      :username
    when 2
      :repository
    else
      :repository_content
    end
  end

  def clone_repo(path)
    repo_url = "https://github.com/#{username_from_path(path)}/#{repository_from_path(path)}.git"
    cmd = "git clone #{repo_url} #{real_path(path)}"
    puts cmd
    system(cmd)
  end

  def logger
    @logger ||= begin
                  l = Logger.new("ghfs.log")
                  l.level = Logger::DEBUG
                  l
                end
  end

  def method_missing(method, *args)
    puts "Method missing: #{method} by #{caller[0]}"
    super
  end
end

gh_fs = GHFS.new
FuseFS.set_root( gh_fs )

at_exit { FuseFS.unmount }

# Mount under a directory given on the command line.
FuseFS.mount_under gh_fs.virt_dir
FuseFS.run

