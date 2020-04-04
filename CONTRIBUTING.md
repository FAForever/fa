Contributing
------------

To contribute, please fork this repository and make pull requests to the
`deploy/fafdevelop` branch.

Use the normal git conventions for commit messages, with the following rules:
 - Subject line shorter than 80 characters
 - No trailing period
 - For non-trivial commits, always include a commit message body, describing the change in detail
 - If there are related issues, reference them in the commit message footer

We use [git flow](http://nvie.com/posts/a-successful-git-branching-model/) for our branch conventions.

When making _backwards incompatible API changes_, do so with a stub function and put in a logging statement including traceback. This gives time for mod authors to change their code, as well as for us to catch any incompatibilities introduced by the change.

Code convention
---------------

Please follow the [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide) as
much as possible.

For file encoding, use UTF-8 and unix-style file endings in the repo (Set core.autocrlf).
