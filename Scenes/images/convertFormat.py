# convert from ply to txt format for our render
from plyfile import PlyData, PlyElement

plydata = PlyData.read('bunny.ply')
output  = open("bunny.txt", 'a')

for idx in range(plydata['vertex'].count):
    vertex = list(plydata['vertex'][idx])
    output.write("{} {:.4f} {:.4f} {:.4f}\n".format("vertex", *vertex[0:3]))

for idx in range(plydata['face'].count):
    indice = list(plydata['face'][idx][0])
    output.write("{} {:d} {:d} {:d}\n".format("tri", *indice[0:3]))
