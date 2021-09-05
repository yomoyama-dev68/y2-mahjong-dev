import glob
import os
import json

images_dir ="/home/me/StudioProjects/web_app_sample/assets/images/*"
fnames = [fname for fname in glob.glob(images_dir)]
fnames.sort()

data_byte_index_map = {}

fw = open('tmp.bin', 'wb')
index = 0
for fname in fnames:
    print(fname)
    f = open(fname, 'rb')
    write_size = fw.write(f.read())
    stem = os.path.splitext(os.path.basename(fname))[0]
    data_byte_index_map[stem] = [index, index + write_size]
    index += write_size
fw.close()

jstr = json.dumps(data_byte_index_map)
jbytes_array = jstr.encode('utf-8')
print(jbytes_array)
jbytes_size_array = len(jbytes_array).to_bytes(4, 'little')
print(jbytes_size_array)

fw = open('images.bin', 'wb')
fw.write(jbytes_size_array)
fw.write(jbytes_array)
fr = open('tmp.bin', 'rb')
fw.write(fr.read())
fw.close()
fr.close()
