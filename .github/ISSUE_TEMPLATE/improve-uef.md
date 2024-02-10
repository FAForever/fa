---
name: Unit improvements for the UEF
about: Suggest visual improvements to a unit that belongs to the UEF
title: ""
labels: "graphics"
assignees: ""
---

# Name of Unit

_Screenshot of unit_

- Blueprint identifier: _e.g., uel0001_

## Lua script related issues

## Effect related issues

- [ ] Tracks are correct (if applicable)
- [ ] Footfalls are correct (if applicable)

## Texture related issues

- [ ] Correct albedo intensity
- [ ] Correct team color channel
- [ ] Correct roughness channel
- [ ] Correct metallic channel(s)
- [ ] Correct normals

## Mesh/bone related issues

- [ ] Bones for target recoil exist
- [ ] Bones for targeting exist (only relevant for large units)
- [ ] LOD1 exists
- [ ] LOD2 exists (optionally)
- [ ] LOD3 exists (optionally)

## Relevant shaders

You can find all relevant shaders in [mesh.fx](/effects/mesh.fx).

- Mesh shader techniques: `Unit_HighFidelity` / `Unit_MedFidelity` / `Unit_LowFidelity`
- Shield shader techniques: `ShieldUEF_MedFidelity` / `ShieldUEF_LowFidelity`

### Relevant texture interpretations

| Mesh shaders | R         | G         | B        | A                                           |
| ------------ | --------- | --------- | -------- | ------------------------------------------- |
| Albedo       | R         | G         | B        | Unused                                      |
| Normals      | Unused    | Y         | Unused   | X                                           |
| Spec         | Roughness | Roughness | Emission | Team color / Metallic + roughness reduction |

Relevant details to individual channels:

- Albedo.R = Red channel of albedo, no other behavior
- Albedo.G = Green channel of albedo, no other behavior
- Albedo.B = Blue channel of albedo, no other behavior
- Albedo.A = Unused

- Normals.R = Unused
- Normals.G = Y direction of normals in tangent space
- Normals.B = Unused
- Normals.A = X direction of normals in tangent space

- Spec.R = Plane cockpit mask and it can reduce roughness and increase albedo if the value is larger than 0.65
- Spec.G = Roughness
- Spec.B = Emission and it increases roughness
- Spec.A = Team color and it decreases roughness