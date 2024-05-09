---
name: Unit improvements for the Cybran faction
about: Suggest visual improvements to a unit that belongs to the Cybran faction
title: ""
labels: "area: graphics"
assignees: ""
---

# Name of Unit

_Screenshot of unit_

- Blueprint identifier: _e.g., url0001_

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

- Mesh shader techniques: `Insect_HighFidelity` / `Insect_MedFidelity` / `Insect_LowFidelity`
- Shield shader techniques: `ShieldCybran_MedFidelity` / `ShieldCybran_LowFidelity`

### Relevant texture interpretations

| Mesh shaders | R        | G         | B        | A                                           |
| ------------ | -------- | --------- | -------- | ------------------------------------------- |
| Albedo       | R        | G         | B        | Unused                                      |
| Normals      | Y (copy) | Y         | Y (copy) | X                                           |
| Spec         | Metallic | Roughness | Emission | Team color / Metallic + roughness reduction |

Relevant details to individual channels for the high-fidelity (PBR) preset:

- Albedo.R = Red channel of albedo
- Albedo.G = Green channel of albedo
- Albedo.B = Blue channel of albedo
- Albedo.A = Unused

- Normals.R = Copied Y direction (to prevent compression artifacts)
- Normals.G = Y direction of normals in tangent space
- Normals.B = Copied Y direction (to prevent compression artifacts)
- Normals.A = X direction of normals in tangent space

- Spec.R = Metallic
- Spec.G = Roughness and increase to metallic if the value is larger than 0.1
- Spec.B = Emission
- Spec.A = Team color and it decreases metallic
