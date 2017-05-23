from wand.image import Image


def mono_array_from_img_obj(img, threshold=200, inverse=False):
    blob = img.make_blob(format='RGB')
    pixels = list()
    if inverse:
        on = 1
        off = 0
    else:
        on = 0
        off = 1
    for y in range(0, img.height):
        current_row = list()
        pixels.append(current_row)
        for x in range(0, img.width * 3, 3):
            loc = y * img.width * 3 + x
            if (ord(blob[loc]) + ord(blob[loc + 1]) + ord(blob[loc + 2])) / 3 >= threshold:
                current_row.append(on)
            else:
                current_row.append(off)
    return pixels


def gen_bitmap_string(rows, width=8, reverse_lr_order=False):
    out_lines = list()
    out_str_fmt = '    .byte #%{0}'
    for row in rows:
        this_line = ''.join([str(x) for x in row])
        if reverse_lr_order:
            this_line = this_line[::-1]
        if width == 4:
            this_line += '0000'
        out_lines.append(this_line)
    out_lines = out_lines[::-1]
    return '\n'.join([out_str_fmt.format(l) for l in out_lines])


def gen_sprite_asm_from_bit_array(bit_array, prefix=''):
    pf0pos1_bytes = [row[0:4] for row in bit_array]
    pf1pos1_bytes = [row[4:12] for row in bit_array]
    pf2pos1_bytes = [row[12:20] for row in bit_array]
    pf0pos2_bytes = [row[20:24] for row in bit_array]
    pf1pos2_bytes = [row[24:32] for row in bit_array]
    pf2pos2_bytes = [row[32:40] for row in bit_array]
    pf0pos1_strings = gen_bitmap_string(pf0pos1_bytes, width=4, reverse_lr_order=True)
    pf1pos1_strings = gen_bitmap_string(pf1pos1_bytes)
    pf2pos1_strings = gen_bitmap_string(pf2pos1_bytes, reverse_lr_order=True)
    pf0pos2_strings = gen_bitmap_string(pf0pos2_bytes, width=4, reverse_lr_order=True)
    pf1pos2_strings = gen_bitmap_string(pf1pos2_bytes)
    pf2pos2_strings = gen_bitmap_string(pf2pos2_bytes, reverse_lr_order=True)
    out = '{0}PF0SpriteA\n{1}\n'.format(prefix, pf0pos1_strings)
    out += '{0}PF0SpriteB\n{1}\n'.format(prefix, pf0pos2_strings)
    out += '{0}PF1SpriteA\n{1}\n'.format(prefix, pf1pos1_strings)
    out += '{0}PF1SpriteB\n{1}\n'.format(prefix, pf1pos2_strings)
    out += '{0}PF2SpriteA\n{1}\n'.format(prefix, pf2pos1_strings)
    out += '{0}PF2SpriteB\n{1}\n'.format(prefix, pf2pos2_strings)
    return out


def bit_array_from_file(filename, r_width=40, r_height=192):
    with Image(filename=filename) as img:
        img.resize(r_width, r_height)
        pixels = mono_array_from_img_obj(img)
    return pixels


def gen_asm_from_image_file(filename, prefix=''):
    bits = bit_array_from_file(filename)
    asm_text = gen_sprite_asm_from_bit_array(bits, prefix=prefix)
    return asm_text






