Contributing
------------

To contribute, please fork this repository and make pull requests to the
develop branch.

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

Documentation
---------------

We use [LDoc](https://stevedonovan.github.io/ldoc/) to generate the documentation to the Lua code. Please make sure that your code complies with the LDoc documentation style. Consult the [LDoc documentation](https://stevedonovan.github.io/ldoc/manual/doc.md.html) for details. 

LDoc documentation comments can be started with _at least_ three hyphens `---` so please take care of faulty usage.

**Example:** 

```lua
--- Displays given forename, surname and the age of 
-- in the current window.
-- @string forename The forename of the person.
-- @string surname The surname of the person.
-- @int age The age of the person.
-- @return Returns the previous information {forname, surname, age}
-- or 'nil' if no previous information was set.
function DisplayPersonInformation (functionParameter)
  -- Implementation
end
``` 
