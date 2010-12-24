GithubFS
=========

A FUSE Filesystem which mapps to github users and repositories.

This is a fun WIP project without tests and very hackish code. It's not ment to be something very useful at the moment, its just a proof of concept!

Usage
--------
* install macfuse: http://code.google.com/p/macfuse/
* install bundler: `gem install bundler`
* run `bundle`

`ruby lib/githubfuse.rb`
will create a ghfs folder and mount the virtual filesystem there.
when you create a folder with the name of a github user in it, its subdirectories will be the users public repositories. 
Accessing a repository directories contents will clone the repository using the public clone url. 

Of course, using something like `tree` in the root directory might not be the best idea because it will clone every repository of every user you've created a user directory for :P

License
--------

This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://sam.zoy.org/wtfpl/COPYING for more details.