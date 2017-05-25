import image_converter
import argparse
import time


def generate_asm_from_images(foreground,
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


def generate_asm(foreground_asm,
                 background_asm,
                 beat_asm,
                 note_asm,
                 out,
                 template,
                 max_music_data_size=400
                 ):

    beat_range_lengths = count_segment_lengths(beat_asm)
    note_range_lengths = count_segment_lengths(note_asm)

    if sum(beat_range_lengths.values()) + sum(note_range_lengths.values()) > max_music_data_size:
        raise Exception('Total music data size of {0} is greater than max of {1}!'.format(sum(beat_range_lengths.values()) + sum(note_range_lengths.values()), max_music_data_size))

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
    parser.add_argument('--foreground_image', type=str, help='Path to foreground image file. If specified, overrides fg_file data', default=None)
    parser.add_argument('--background_image', type=str, help='Path to background image file. If specified, overrides bg_file data', default=None)
    parser.add_argument('--fg_file', type=str, help='Path to file containing foreground ASM data, default dehuman_foreground_data.asm', default='dehuman_foreground_data.asm')
    parser.add_argument('--bg_file', type=str, help='Path to file containing background ASM data, default dehuman_background_data.asm', default='dehuman_background_data.asm')
    parser.add_argument('--beat_file', type=str, help='Path to file containing beat data, default dehuman_beat_data.asm', default='dehuman_beat_data.asm')
    parser.add_argument('--note_file', type=str, help='Path to file containing note data, default dehuman_note_data.asm', default='dehuman_note_data.asm')
    parser.add_argument('--template', type=str, help='Path to template asm file, default dehuman_template.asm', default='dehuman_template.asm')
    parser.add_argument('--out_file', type=str, help='Path to write output file, default dehuman_generated_<timestamp>.asm', default=None)

    args = parser.parse_args()

    if args.out_file is None:
        args.out_file = 'dehuman_generated_{0}.asm'.format(int(time.time()))

    if args.foreground_image is None:
        with open(args.fg_file) as f:
            print('Using pre-constructed ASM in file {0} for foreground image'.format(args.fg_file))
            fg_asm = f.read()
    else:
        print('Using image file {0} for foreground image'.format(args.foreground_image))
        fg_asm = image_converter.gen_asm_from_image_file(args.foreground_image)

    if args.background_image is None:
        with open(args.bg_file) as f:
            print('Using pre-constructed ASM in file {0} for background image'.format(args.bg_file))
            bg_asm = f.read()
    else:
        print('Using image file {0} for background image'.format(args.background_image))
        bg_asm = image_converter.gen_asm_from_image_file(args.backround_image)

    print('Using beat data from {0} and note data from {1}'.format(args.beat_file, args.note_file))

    with open(args.beat_file) as f:
        beat_data = f.read()
    with open(args.note_file) as f:
        note_data = f.read()

    print('Generating ASM using template {0}'.format(args.template))
    generate_asm(fg_asm, bg_asm, beat_data, note_data, args.out_file, args.template)

    print('Generated ASM written to {0}'.format(args.out_file))
