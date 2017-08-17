#****************************************************************************
#**
#**  File     :  /lua/system/GlobalInit.lua
#**
#**  Summary  : The Unit lua module
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

# Flag initial loading of blueprints
InitialRegistration = true

# Load blueprint systems
doscript '/lua/system/BuffBlueprints.lua'

# Load buff definitions
import('/lua/sim/BuffDefinitions.lua')

# Load Platoon Template systems
doscript '/lua/system/GlobalPlatoonTemplate.lua'

# Load Builder system
doscript '/lua/system/GlobalBuilderTemplate.lua'

# Load Builder Group systems
doscript '/lua/system/GlobalBuilderGroup.lua'

# Load Global Base Templates
doscript '/lua/system/GlobalBaseTemplate.lua'

InitialRegistration = false
