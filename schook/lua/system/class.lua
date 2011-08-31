function startClass(...)   ###added for shipwreck mod
	-- class prototype table
	local proto = {}
	-- original caller environment
	local env = getfenv(2)
	
	-- the default 'endClass' function
	-- the metamethod for __newindex above will override this if the user behaves
	-- if this gets called, they _aren't_ behaving, so error
	function proto.endClass()
		error("Attempted to create a class without assigning it to anything!")
	end	

	-- metatable for prototype
	local mt = {}
	
	-- __index: retain access to global variables
	mt.__index = env
	
	-- __newindex: trap the first assignment so that MyClass = startClass(...) works
	function mt:__newindex(key, value)
		-- delete ourselves; we only want to trigger on the first assignment
		mt.__newindex = nil
		
		-- new endClass() function that does the real work
		function proto.endClass()
			-- restore original environment
			setfenv(2, env)
			-- tidy up
			proto.endClass = nil
			setmetatable(proto, nil)
			for k,v in pairs(proto) do
				if type(v) == 'function' then
					setfenv(v, env)
				end
			end
			-- create class object and assign to caller's environment with the
			-- key they originally specified
			if arg.n == 0 then
				env[key] = Class(proto)
			else
				env[key] = Class(unpack(arg))(proto)
			end
		end
	end
	
	setmetatable(proto, mt)
	setfenv(2, proto)
end
