How to import more units
-----------------------------

- If you haven't already, install the supcom importer addon from here: https://github.com/Solstice245/scstudio
Download the repository as a zip file, then install it from blender as an addon. Keep the file zipped for this.

- Import the unit you want through file > import > supreme commander model. The unit will have a material already attached, but we don't need that one.
- Change the material that the importer assigned to one of the PBR materials. It's named after the corresponding faction. In a shader editor you can change it by clicking the ball (red arrow).
- By default blender will just link to the existing material. Changes here would also affect the original object you got this material from. Make this material a single user by pressing the "2" (yellow arrow).
- You can now change the textures to the ones appropriate for your new model. Press the "x" (blue arrow), then you can open a new texture. Browse to the correct folder and select the right texture.
- As a last step you need to make sure that the SpecTeam and Normal map use Non-Color colorspace (green arrows). Otherwise the unit will look kind of odd and blender likes to reset it to sRGB colorspace when changing the image.
- If you want to look inside the node group you can select it and open it with "tab".

![The new material](/blender/Shader.jpg)

