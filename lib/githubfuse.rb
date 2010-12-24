require 'rubygems'
require 'octopi'
require 'fusefs'

class GHFS
  def initialize
    @users = {}
    @repos = {}
  end

  def contents(path)
    case path_type(path)
    when :root
      @users.keys
    when :username
      get_repos(username_from_path(path)).map{|r| r.name}
    when :repository

    when :repository_content

    end
  end

  def get_repos(username)
    @repos[username] ||= @users[username].repositories
  end

  def file?(path)
    path == '/hello.txt'
  end

  def directory?(path)
    case path_type(path)
    when :root
      true
    when :username
      @users[username_from_path(path)]
    when :repository
      get_repos(username_from_path(path)).any? {|r| r.name == repository_from_path(path)}
    end
  end

  def read_file(path)
    "Hello, World!\n"
  end

  def can_mkdir?(path)
    !!get_user(username_from_path(path))
  end

  def mkdir(path)

  end

  def can_write?(path)
    false
  end

  def can_delete?(path)
    false
  end

  private
  def get_user(username)
    @users[username] ||= Octopi::User.find(username)
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

  def method_missing(method, *args)
p    caller[0]
    puts method
    super
  end
end

gh_fs = GHFS.new
FuseFS.set_root( gh_fs )

# Mount under a directory given on the command line.
FuseFS.mount_under ARGV.shift
FuseFS.run
