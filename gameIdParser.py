filename = 'uuidsRaw.txt'
outfile = 'uuids.txt'

count = 0
out = open(outfile, 'w')
with open(filename) as f:
    for line in f:
        if count % 20 == 0:
            out.write("\n// Index {0}\n".format(count))
        out.write('"{0}",\n'.format(line.strip()))
        count += 1
out.close()
