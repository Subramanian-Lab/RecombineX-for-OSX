import sys

def read_chr_dict(file_path):
    chr_dict = {}
    with open(file_path) as f:
        for line in f:
            if line.startswith('#') or line.strip() == "":
                continue
            tag, query, target = line.strip().split('\t')
            chr_dict[query] = target
    return chr_dict

def reformat_header(old_header_path, chr_dict, new_header_path):
    with open(old_header_path) as f, open(new_header_path, 'w') as out_f:
        for line in f:
            if line.startswith('@SQ'):
                parts = line.split()
                for part in parts:
                    if part.startswith('SN:'):
                        old_chr = part.split(':')[1]
                        new_chr = chr_dict.get(old_chr, old_chr)
                        part = f'SN:{new_chr}'
                out_f.write(' '.join(parts) + '\n')
            else:
                out_f.write(line)

if __name__ == "__main__":
    old_header = sys.argv[1]
    chr_dict_path = sys.argv[2]
    new_header = sys.argv[3]

    chr_dict = read_chr_dict(chr_dict_path)
    reformat_header(old_header, chr_dict, new_header)

