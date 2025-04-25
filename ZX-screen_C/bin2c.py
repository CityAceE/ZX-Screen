import sys

def bin_to_c_array(filename, array_name):
    with open(filename, 'rb') as f:
        data = f.read()
    hex_data = ', '.join(f'0x{byte:02x}' for byte in data)
    c_code = f"const unsigned char {array_name}[] = {{\n  {hex_data}\n}};\n"
    c_code += f"const size_t {array_name}_size = {len(data)};\n"
    return c_code

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python bin2c.py <input.bin> <output.h>")
        sys.exit(1)
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    array_name = input_file.replace('.', '_')
    c_code = bin_to_c_array(input_file, array_name)
    with open(output_file, 'w') as f:
        f.write(c_code)