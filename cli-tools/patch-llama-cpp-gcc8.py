#!/usr/bin/env python3
"""Apply the pinned b10516 server-schema GCC 8 CTAD compatibility fix."""
import argparse
import hashlib
from pathlib import Path

ORIGINAL_SHA256 = 'ca6db259fadf6a8bfc182407d539398c803e4db4e288cabec9891990a875b946'
PATCHED_SHA256 = 'a3bff4515bc30b5a51b3b2eaa8c8e23eca9b22093433dab667fa7ce353686308'
ANCHOR = 'namespace server_schema {\n'
OLD_EXPRESSION = 'new field_num('
EXPECTED_OCCURRENCES = 42
HELPER = '''
// Zorks compatibility: GCC 8 cannot deduce field_num<T> in this new-expression.
// Function-template deduction supplies exactly the constructor's original T.
template <typename T>
static field_num<T> * zorks_make_field_num(const char * name, T & value) {
    return new field_num<T>(name, value);
}
'''


def compatible_text(text):
    if text.count(ANCHOR) != 1:
        raise ValueError('Unexpected server_schema namespace layout')
    if text.count(OLD_EXPRESSION) != EXPECTED_OCCURRENCES:
        raise ValueError('Unexpected number of field_num constructors')
    return text.replace(ANCHOR, ANCHOR + HELPER, 1).replace(
        OLD_EXPRESSION, 'zorks_make_field_num(')


def patch_schema(source_dir):
    path = Path(source_dir) / 'tools' / 'server' / 'server-schema.cpp'
    original = path.read_bytes()
    digest = hashlib.sha256(original).hexdigest()
    if digest == PATCHED_SHA256:
        print('GCC 8 server-schema compatibility patch is already applied.')
        return False
    if digest != ORIGINAL_SHA256:
        raise ValueError('Unexpected server-schema.cpp content; preserving the file. '
                         'This compatibility patch targets the pinned b10516 source.')
    patched = compatible_text(original.decode('utf-8')).encode('utf-8')
    if hashlib.sha256(patched).hexdigest() != PATCHED_SHA256:
        raise ValueError('The generated GCC 8 compatibility patch failed its checksum check')
    path.write_bytes(patched)
    print('Applied GCC 8 server-schema compatibility patch.')
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source_dir', type=Path)
    args = parser.parse_args()
    try:
        patch_schema(args.source_dir)
    except (OSError, UnicodeError, ValueError) as error:
        parser.exit(1, 'GCC 8 compatibility patch failed: ' + str(error) + '\n')


if __name__ == '__main__':
    main()
