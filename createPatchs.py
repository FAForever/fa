import os
import zipfile

patch = 3633

folders = ["effects", "ENV", "LOC", "lua", "meshes", "mods", "modules", "projectiles", "SCHOOK", "textures", "units"]

dest = r"/var/www/faf/updaterNew/updates_faf_files"



def zipdir(path):
    '''zips the entire directory path to zipf. Every file in the zipfile starts with fname.
    So if path is "/foo/bar/hello" and fname is "test" then every file in zipf is of the form "/test/*.*"'''
    path = os.path.normcase(path)
    paths = []
    if path[-1] in r'\/':
        path = path[:-1]
    short = os.path.split(path)[0]
    for root, dirs, files in os.walk(path):
        dirs.sort()
        for f in sorted(files):
            name = os.path.join(os.path.normcase(root), f)
            print name
            n = name[len(os.path.commonprefix([name,path])):]
            paths.append((n.lower(),name))


            # zipf.write(name, os.path.join(fname,n))
    return paths




for folder in folders:
        archive_num = 0
        zsize = 0

        filename = os.path.join(dest, "%s_%i.%i.nxt" % (folder.lower(), archive_num, patch))

        zipped = zipfile.ZipFile(filename, "w", zipfile.ZIP_DEFLATED)
        filelist = zipdir(folder)
        for n, path in filelist:
                print n, path
#               if zsize > 10485760 : # 10mb
#                       zipped.close()
#                       archive_num += 1
#                       filename = os.path.join(dest, "%s_%i.%i.nxt" % (folder.lower(), archive_num, patch))
#                       zipped = zipfile.ZipFile(filename, "w", zipfile.ZIP_DEFLATED)
#                       zsize= 0
                zipped.write(path, path)

#               zsize += zipped.getinfo(path).compress_size #  get compressed size of file
