//! Rust-based txt2hex

use std::{
    env,
    fs::File,
    io::prelude::*,
    path::Path,
};

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let mut file = File::open(filename).expect("Unable to read file");
    let mut chars = Vec::new();
    file.read_to_end(&mut chars).unwrap();
    // output file
    let opath = Path::new(filename).with_extension("").with_extension("hex");
    let mut ofile = File::create(opath).unwrap();
    let mut char_iter = chars.into_iter();
    let mut addr = 0;
    write!(&mut ofile, "@{:08x}", addr).unwrap();
    let mut line_len = 10;
    while let Some(c) = char_iter.next()
    {
        if c == '\n' as u8
        {
            write!(&mut ofile, " {:02x}", '\r' as u8).unwrap();
            addr += 1;
            line_len += 3;
            if line_len > 56
            {
                write!(&mut ofile, "\n@{:08x}",addr).unwrap();
                line_len = 10;
            }
        }
        write!(&mut ofile, " {:02x}", c).unwrap();
        addr += 1;
        line_len += 3;
        if line_len > 56
        {
            write!(&mut ofile, "\n@{:08x}",addr).unwrap();
            line_len = 10;
        }
    }
    while addr < 2048
    {
        write!(&mut ofile, " {:02x}", ' ' as u8).unwrap();
        addr += 1;
        line_len += 3;
        if line_len > 56
        {
            write!(&mut ofile, "\n@{:08x}",addr).unwrap();
            line_len = 10;
        }
    }
}
