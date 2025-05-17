- (#6784) Implement proper transfer of unbuilt units in factories.

  Previously, unbuilt units inside factories would be rebuilt on the ground after a transfer, and this would only happen after an army is defeated. It was awkward to finish rebuilding the unit and it could block the factory.  
  Now, unbuilt units are rebuilt inside the new factory like with any other factory build, and this happens with all ownership transfers.

- (#6784) Improve consistency of veterancy dispersal for factories.

  When a transport dies, it disperses the mass cost of its cargo as veterancy. The same now applies to factories and their unbuilt units. This includes external factories.

- (#6784) Make Fatboy's external factory create unit wrecks at above 50% completion just like normal factories.
