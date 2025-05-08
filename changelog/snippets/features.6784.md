- (#6784) Implement proper transfer of unbuilt units in factories.

  Previously, unbuilt units inside factories would be rebuilt on the ground after a transfer, and this would only happen after an army is defeated. It was awkward to finish rebuilding the unit and it could block the factory.  
  Now, unbuilt units are rebuilt inside the new factory like with any other factory build, and this happens with all ownership transfers.
