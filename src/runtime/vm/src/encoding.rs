fn canonical_code(code: &[Instruction]) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, code.len() as u64);
    for instruction in code {
        bytes.push(match instruction.op {
            Op::PushLiteral => 0,
            Op::PushQuote => 1,
            Op::PushCapture => 2,
            Op::Dup => 3,
            Op::Drop => 4,
            Op::Swap => 5,
            Op::Call => 6,
            Op::Dip => 7,
            Op::Compose => 8,
            Op::Quote => 9,
            Op::If => 10,
            Op::CallWord => 11,
            Op::Prim => 12,
        });
        match instruction.operand.as_ref() {
            Some(Operand::Literal(value)) => canonical_value(&mut bytes, value),
            Some(Operand::Quote(quotation)) => {
                bytes.extend(canonical_code(&quotation.code));
                put_unsigned(&mut bytes, quotation.captures.len() as u64);
                let mut bitmap = vec![0; quotation.captures.len().div_ceil(8)];
                for (index, consumed) in quotation.consumed.iter().copied().enumerate() {
                    if consumed {
                        bitmap[index / 8] |= 1 << (index % 8);
                    }
                }
                bytes.extend(bitmap);
                for capture in &quotation.captures {
                    canonical_value(&mut bytes, capture);
                }
            }
            Some(Operand::Capture(index)) => put_unsigned(&mut bytes, *index),
            Some(Operand::Word(name)) | Some(Operand::Primitive(name)) => {
                put_string(&mut bytes, name)
            }
            None => {}
        }
    }
    bytes
}

fn canonical_value(bytes: &mut Vec<u8>, value: &Value) {
    match value {
        Value::Int(value) => {
            bytes.push(0);
            put_unsigned(bytes, ((*value as u64) << 1) ^ ((*value >> 63) as u64));
        }
        Value::Bool(value) => {
            bytes.extend([1, u8::from(*value)]);
        }
        Value::Bytes(value) => {
            bytes.push(2);
            put_string_bytes(bytes, value);
        }
        Value::Quotation(quotation) => {
            bytes.push(3);
            bytes.extend(canonical_code(&quotation.code));
            put_unsigned(bytes, quotation.captures.len() as u64);
            let mut bitmap = vec![0; quotation.captures.len().div_ceil(8)];
            for (index, consumed) in quotation.consumed.iter().copied().enumerate() {
                if consumed {
                    bitmap[index / 8] |= 1 << (index % 8);
                }
            }
            bytes.extend(bitmap);
            for capture in &quotation.captures {
                canonical_value(bytes, capture);
            }
        }
        Value::PrimitiveValue { tag, bytes: value } => {
            bytes.push(4);
            put_unsigned(bytes, *tag);
            put_string_bytes(bytes, value);
        }
        Value::World => bytes.push(5),
    }
}

fn canonical_dictionary(words: &[WordEntry]) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, words.len() as u64);
    for word in words {
        put_string(&mut bytes, &word.name);
        put_string(&mut bytes, &word.erased_word_type);
        bytes.extend(canonical_code(&word.code));
        bytes.extend(&word.body_digest);
        bytes.extend(&word.kernel_evidence_digest);
        bytes.extend(&word.refinement_evidence_digest);
        put_unsigned(&mut bytes, word.generation);
    }
    bytes
}

fn canonical_image_identity(
    format_version: u16,
    image_version: u64,
    gamma_version: u64,
    dictionary_digest: &[u8],
) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, u64::from(format_version));
    put_unsigned(&mut bytes, image_version);
    put_unsigned(&mut bytes, gamma_version);
    bytes.extend(dictionary_digest);
    bytes
}

fn put_string_bytes(bytes: &mut Vec<u8>, value: &[u8]) {
    put_unsigned(bytes, value.len() as u64);
    bytes.extend(value);
}

// SHA-256, specified by target-spec.md §7 and kept dependency-free for no_std.
fn sha256(input: &[u8]) -> [u8; DIGEST_BYTES] {
    const K: [u32; 64] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
        0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
        0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
        0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
        0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
        0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
        0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
        0xc67178f2,
    ];
    let mut h: [u32; 8] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab,
        0x5be0cd19,
    ];
    let bit_len = (input.len() as u64).wrapping_mul(8);
    let padded_len = (input.len() + 9).div_ceil(64) * 64;
    let mut padded = vec![0; padded_len];
    padded[..input.len()].copy_from_slice(input);
    padded[input.len()] = 0x80;
    padded[padded_len - 8..].copy_from_slice(&bit_len.to_be_bytes());
    for chunk in padded.chunks_exact(64) {
        let mut w = [0u32; 64];
        for i in 0..16 {
            w[i] = u32::from_be_bytes([
                chunk[i * 4],
                chunk[i * 4 + 1],
                chunk[i * 4 + 2],
                chunk[i * 4 + 3],
            ]);
        }
        for i in 16..64 {
            let s0 = w[i - 15].rotate_right(7) ^ w[i - 15].rotate_right(18) ^ (w[i - 15] >> 3);
            let s1 = w[i - 2].rotate_right(17) ^ w[i - 2].rotate_right(19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16]
                .wrapping_add(s0)
                .wrapping_add(w[i - 7])
                .wrapping_add(s1);
        }
        let (mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut hh) =
            (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]);
        for i in 0..64 {
            let s1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25);
            let ch = (e & f) ^ ((!e) & g);
            let t1 = hh
                .wrapping_add(s1)
                .wrapping_add(ch)
                .wrapping_add(K[i])
                .wrapping_add(w[i]);
            let s0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22);
            let maj = (a & b) ^ (a & c) ^ (b & c);
            let t2 = s0.wrapping_add(maj);
            (hh, g, f, e, d, c, b, a) = (g, f, e, d.wrapping_add(t1), c, b, a, t1.wrapping_add(t2));
        }
        for (value, add) in h.iter_mut().zip([a, b, c, d, e, f, g, hh]) {
            *value = (*value).wrapping_add(add);
        }
    }
    let mut result = [0; DIGEST_BYTES];
    for (i, value) in h.into_iter().enumerate() {
        result[i * 4..i * 4 + 4].copy_from_slice(&value.to_be_bytes());
    }
    result
}

fn put_unsigned(bytes: &mut Vec<u8>, mut value: u64) {
    loop {
        let mut byte = (value & 0x7f) as u8;
        value >>= 7;
        if value != 0 {
            byte |= 0x80;
        }
        bytes.push(byte);
        if value == 0 {
            return;
        }
    }
}

fn put_string(bytes: &mut Vec<u8>, value: &str) {
    put_unsigned(bytes, value.len() as u64);
    bytes.extend(value.as_bytes());
}

struct Reader<'a> {
    bytes: &'a [u8],
    position: usize,
}

impl<'a> Reader<'a> {
    fn new(bytes: &'a [u8]) -> Self {
        Self { bytes, position: 0 }
    }
    fn remaining(&self) -> &[u8] {
        &self.bytes[self.position..]
    }
    fn byte(&mut self) -> Result<u8, VmError> {
        let byte = *self.bytes.get(self.position).ok_or(VmError::Truncated)?;
        self.position += 1;
        Ok(byte)
    }
    fn take(&mut self, count: usize) -> Result<&'a [u8], VmError> {
        let end = self
            .position
            .checked_add(count)
            .ok_or(VmError::LengthLimit)?;
        let result = self
            .bytes
            .get(self.position..end)
            .ok_or(VmError::Truncated)?;
        self.position = end;
        Ok(result)
    }
    fn unsigned(&mut self) -> Result<u64, VmError> {
        let mut value = 0u64;
        for index in 0..10 {
            let byte = self.byte()?;
            let payload = u64::from(byte & 0x7f);
            if index == 9 && (byte & 0x80 != 0 || payload > 1) {
                return Err(VmError::InvalidLeb128);
            }
            value |= payload << (index * 7);
            if byte & 0x80 == 0 {
                if index > 0 && value < (1u64 << (index * 7)) {
                    return Err(VmError::NonCanonicalLeb128);
                }
                return Ok(value);
            }
        }
        Err(VmError::InvalidLeb128)
    }
    fn signed(&mut self) -> Result<i64, VmError> {
        let value = self.unsigned()?;
        Ok(((value >> 1) as i64) ^ -((value & 1) as i64))
    }
    fn bounded_len(&mut self) -> Result<usize, VmError> {
        let length = self.unsigned()?;
        let length = usize::try_from(length).map_err(|_| VmError::LengthLimit)?;
        if length > MAX_BYTES || length > self.remaining().len() {
            return Err(if length > MAX_BYTES {
                VmError::LengthLimit
            } else {
                VmError::Truncated
            });
        }
        Ok(length)
    }
    fn bytes(&mut self) -> Result<&'a [u8], VmError> {
        let length = self.bounded_len()?;
        self.take(length)
    }
    fn string(&mut self) -> Result<String, VmError> {
        String::from_utf8(self.bytes()?.to_vec()).map_err(|_| VmError::InvalidUtf8)
    }
    fn digest(&mut self) -> Result<Vec<u8>, VmError> {
        let bytes = self.take(DIGEST_BYTES)?;
        Ok(bytes.to_vec())
    }
    fn count(&mut self) -> Result<usize, VmError> {
        let count = self.unsigned()?;
        if count > MAX_INSTRUCTIONS {
            return Err(VmError::InstructionLimit);
        }
        usize::try_from(count).map_err(|_| VmError::LengthLimit)
    }
    fn count_for(&mut self, count: usize) -> Result<&'a [u8], VmError> {
        if count > MAX_BYTES {
            return Err(VmError::LengthLimit);
        }
        self.take(count)
    }
    fn vector<T>(
        &mut self,
        mut decode: impl FnMut(&mut Self) -> Result<T, VmError>,
    ) -> Result<Vec<T>, VmError> {
        let count = self.count()?;
        let mut values = Vec::with_capacity(count);
        for _ in 0..count {
            values.push(decode(self)?);
        }
        Ok(values)
    }
}

