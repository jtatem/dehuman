import image_converter
import argparse
import time


def generate_asm(foreground,
                 background,
                 out,
                 template):
    foreground_asm = image_converter.gen_asm_from_image_file(foreground)
    background_asm = image_converter.gen_asm_from_image_file(background, prefix='Alt')

    with open(template) as f:
        asm_text = f.read()
    asm_text = asm_text.format(ForegroundImage=foreground_asm, BackgroundImage=background_asm)

    with open(out, 'w') as f:
        f.write(asm_text)

    return asm_text


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('foreground_image', type=str, nargs=1, help='Path to foreground image file')
    parser.add_argument('background_image', type=str, nargs=1, help='Path to background image file')
    parser.add_argument('--template', type=str, help='Path to template asm file, default dehuman_template.asm', default='dehuman_template.asm')
    parser.add_argument('--out_file', type=str, help='Path to write output file, default dehuman_generated_<timestamp>.asm', default=None)

    args = parser.parse_args()

    if args.out_file is None:
        args.out_file = 'dehuman_generated_{0}.asm'.format(int(time.time()))

    print('Generating ASM using images {0} and {1} with template {2}'.format(args.foreground_image[0],
                                                                                                 args.background_image[0],
                                                                                                 args.template,
                                                                                                 args.out_file))
    generate_asm(args.foreground_image[0], args.background_image[0], args.out_file, args.template)
    print('Generated ASM written to {0}'.format(args.out_file))
