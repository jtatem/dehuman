import image_converter
import argparse
import time


def generate_asm(foreground,
                 background,
                 beat_data,
                 note_data,
                 out,
                 template):
    foreground_asm = image_converter.gen_asm_from_image_file(foreground)
    background_asm = image_converter.gen_asm_from_image_file(background, prefix='Alt')
    with open(beat_data) as f:
        beat_asm = f.read()

    with open(note_data) as f:
        note_asm = f.read()

    beat_range_lengths = count_segment_lengths(beat_asm)
    note_range_lengths = count_segment_lengths(note_asm)

    with open(template) as f:
        asm_text = f.read()
    asm_text = asm_text.format(ForegroundImage=foreground_asm,
                               BackgroundImage=background_asm,
                               BeatData=beat_asm,
                               NoteData=note_asm,
                               BeatDataALen=beat_range_lengths['A'],
                               BeatDataBLen=beat_range_lengths['B'],
                               BeatDataCLen=beat_range_lengths['C'],
                               NoteDataALen=note_range_lengths['A'],
                               NoteDataBLen=note_range_lengths['B'],
                               NoteDataCLen=note_range_lengths['C']
                               )

    with open(out, 'w') as f:
        f.write(asm_text)

    return asm_text


def count_segment_lengths(asm_text):
    segment_name = None
    results = dict()
    for line in asm_text.split('\n'):
        if 'ControlData' in line:
            segment_name = line.strip()[-1]
            results[segment_name] = 0
        if '.byte' in line and segment_name is not None:
            results[segment_name] += 1
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('foreground_image', type=str, nargs=1, help='Path to foreground image file')
    parser.add_argument('background_image', type=str, nargs=1, help='Path to background image file')
    parser.add_argument('--beat_file', type=str, nargs=1, help='Path to file containing beat data, default dehuman_beat_data.asm', default='dehuman_beat_data.asm')
    parser.add_argument('--note_file', type=str, nargs=1,help='Path to file containing note data, default dehuman_note_data.asm', default='dehuman_note_data.asm')
    parser.add_argument('--template', type=str, help='Path to template asm file, default dehuman_template.asm', default='dehuman_template.asm')
    parser.add_argument('--out_file', type=str, help='Path to write output file, default dehuman_generated_<timestamp>.asm', default=None)

    args = parser.parse_args()

    if args.out_file is None:
        args.out_file = 'dehuman_generated_{0}.asm'.format(int(time.time()))

    print('Generating ASM using images {0} and {1} with template {2}'.format(args.foreground_image[0],
                                                                             args.background_image[0],
                                                                             args.template))
    generate_asm(args.foreground_image[0], args.background_image[0], args.beat_file, args.note_file, args.out_file, args.template)
    print('Generated ASM written to {0}'.format(args.out_file))
