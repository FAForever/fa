---
name: Unit improvements for the UEF
about: Suggest visual improvements to a unit that belongs to the UEF
title: ""
labels: "graphics"
assignees: ""
---

## Lua script related issues

## Texture related issues

- [ ] Correct albedo intensity
- [ ] Correct team color channel
- [ ] Correct roughness channel
- [ ] Correct metallic channel(s)
- [ ] Correct are wrong

## Mesh/bone related issues

- [ ] Bones for target recoil exist
- [ ] Bones for targeting exist (only relevant for large units)

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
