import os
import sys
import os.path
import hashlib

if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise Exception("Hash program requires an input and output directory argument.")
    dir = sys.argv[1]
    out_file = sys.argv[2]
    
    hashes = []

    files = [file for file in os.listdir(dir) if os.path.isfile(os.path.join(dir, file))]
    for file in files:
        with open(os.path.join(dir, file), "rb") as f:
            digest = hashlib.file_digest(f, "sha1").hexdigest()
            hashes.append(digest + " " + file)
    
    with open(out_file, "w") as f:
        f.write("\n".join(hashes))
