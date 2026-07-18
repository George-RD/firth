fn is_canonical_word_type(value: &str) -> bool {
    let bytes = value.as_bytes();
    if bytes.first() != Some(&b'(')
        || bytes.last() != Some(&b')')
        || value.chars().any(char::is_whitespace)
    {
        return false;
    }
    let mut parser = WordTypeParser {
        bytes,
        position: 1,
        rows: Vec::new(),
        quotation_depth: 0,
    };
    parser.parse()
}

struct WordTypeParser<'a> {
    bytes: &'a [u8],
    position: usize,
    rows: Vec<&'a [u8]>,
    quotation_depth: usize,
}

impl<'a> WordTypeParser<'a> {
    fn parse(&mut self) -> bool {
        if self.consume(b"forall") {
            let mut count = 0;
            loop {
                let row = match self.row_name() {
                    Some(row) => row,
                    None => return false,
                };
                if !is_row_name(row) {
                    return false;
                }
                self.rows.push(row);
                count += 1;
                if self.consume_byte(b';') {
                    break;
                }
                if !self.consume_byte(b',') {
                    return false;
                }
            }
            if count == 0 {
                return false;
            }
        }
        if !self.stack_items() || !self.consume(b"--") || !self.stack_items() {
            return false;
        }
        self.position + 1 == self.bytes.len()
    }

    fn stack_items(&mut self) -> bool {
        let mut count = 0;
        if self.bytes[self.position..].starts_with(b"--")
            || matches!(self.bytes.get(self.position), Some(b')' | b']'))
        {
            return true;
        }
        loop {
            if self.peek_byte() == Some(b'[') {
                return false;
            }
            let item = match self.identifier().or_else(|| self.row_name()) {
                Some(item) => item,
                None => return false,
            };
            if self.consume_byte(b':') {
                if !is_canonical_identifier(item) || !self.value_type() {
                    return false;
                }
            } else if !is_row_name(item) || self.rows.is_empty() || !self.rows.contains(&item) {
                return false;
            }
            count += 1;
            if self.bytes[self.position..].starts_with(b"--")
                || matches!(self.bytes.get(self.position), Some(b')' | b']'))
            {
                break;
            }
            if !self.consume_byte(b',') {
                return false;
            }
            if self.bytes[self.position..].starts_with(b"--")
                || matches!(self.bytes.get(self.position), Some(b')' | b']'))
            {
                return false;
            }
        }
        count > 0
    }

    fn value_type(&mut self) -> bool {
        if self.consume_byte(b'[') {
            if self.quotation_depth >= MAX_WORD_TYPE_NESTING {
                return false;
            }
            self.quotation_depth += 1;
            if !self.stack_items() || !self.consume(b"--") || !self.stack_items() {
                return false;
            }
            if !self.consume_byte(b']') {
                return false;
            }
            self.quotation_depth -= 1;
        } else {
            let type_name = match self.identifier() {
                Some(type_name) => type_name,
                None => return false,
            };
            if !is_canonical_identifier(type_name) {
                return false;
            }
        }
        if self.consume_byte(b'^') && !self.consume(b"many") && !self.consume(b"linear") {
            return false;
        }
        true
    }

    fn identifier(&mut self) -> Option<&'a [u8]> {
        let start = self.position;
        if self
            .bytes
            .get(self.position)
            .is_some_and(|byte| *byte >= 0x80)
        {
            let first = self.bytes[self.position];
            let width = if first & 0xe0 == 0xc0 {
                2
            } else if first & 0xf0 == 0xe0 {
                3
            } else if first & 0xf8 == 0xf0 {
                4
            } else {
                return None;
            };
            let end = self.position.checked_add(width)?;
            if end > self.bytes.len()
                || !self.bytes[self.position + 1..end]
                    .iter()
                    .all(|byte| *byte & 0xc0 == 0x80)
                || core::str::from_utf8(&self.bytes[self.position..end])
                    .ok()?
                    .chars()
                    .count()
                    != 1
            {
                return None;
            }
            self.position = end;
            return Some(&self.bytes[start..end]);
        }
        while self.position < self.bytes.len()
            && (self.bytes[self.position].is_ascii_alphanumeric()
                || self.bytes[self.position] == b'_')
        {
            self.position += 1;
        }
        (self.position > start).then(|| &self.bytes[start..self.position])
    }

    fn row_name(&mut self) -> Option<&'a [u8]> {
        let start = self.position;
        let first = *self.bytes.get(self.position)?;
        let width = if first < 0x80 {
            1
        } else if first & 0xe0 == 0xc0 {
            2
        } else if first & 0xf0 == 0xe0 {
            3
        } else if first & 0xf8 == 0xf0 {
            4
        } else {
            return None;
        };
        let end = self.position.checked_add(width)?;
        let value = self.bytes.get(start..end)?;
        let scalar = core::str::from_utf8(value).ok()?.chars().next()?;
        if scalar.is_whitespace()
            || matches!(scalar, ',' | ';' | ':' | '^' | '(' | ')' | '[' | ']' | '-')
        {
            return None;
        }
        self.position = end;
        Some(value)
    }

    fn peek_byte(&self) -> Option<u8> {
        self.bytes.get(self.position).copied()
    }

    fn consume(&mut self, text: &[u8]) -> bool {
        self.bytes.get(self.position..self.position + text.len()) == Some(text) && {
            self.position += text.len();
            true
        }
    }

    fn consume_byte(&mut self, byte: u8) -> bool {
        self.bytes.get(self.position) == Some(&byte) && {
            self.position += 1;
            true
        }
    }
}

fn is_row_name(value: &[u8]) -> bool {
    let mut parser = WordTypeParser {
        bytes: value,
        position: 0,
        rows: Vec::new(),
        quotation_depth: 0,
    };
    parser.row_name().is_some() && parser.position == value.len()
}

fn is_canonical_identifier(value: &[u8]) -> bool {
    let Some((&first, rest)) = value.split_first() else {
        return false;
    };
    (first.is_ascii_alphabetic() || first == b'_')
        && rest
            .iter()
            .all(|byte| byte.is_ascii_alphanumeric() || *byte == b'_')
}

/// Canonical minimal image used by the CLI smoke test: a `main` word pushing 42.
pub fn smoke_image() -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, u64::from(FORMAT_VERSION));
    put_unsigned(&mut bytes, 1);
    put_unsigned(&mut bytes, GAMMA_VERSION);
    put_unsigned(&mut bytes, 1);
    put_string(&mut bytes, "main");
    put_string(&mut bytes, "(--)");
    put_unsigned(&mut bytes, 1);
    bytes.push(0);
    bytes.push(0);
    put_unsigned(&mut bytes, 42 << 1);
    let body_digest = sha256(&canonical_code(&[Instruction {
        op: Op::PushLiteral,
        operand: Some(Operand::Literal(Value::Int(42))),
    }]));
    bytes.extend(body_digest);
    bytes.extend(sha256(&[]));
    bytes.extend(sha256(&[]));
    put_unsigned(&mut bytes, 1);
    let word = WordEntry {
        name: String::from("main"),
        erased_word_type: String::from("(--)"),
        code: vec![Instruction {
            op: Op::PushLiteral,
            operand: Some(Operand::Literal(Value::Int(42))),
        }],
        body_digest: sha256(&canonical_code(&[Instruction {
            op: Op::PushLiteral,
            operand: Some(Operand::Literal(Value::Int(42))),
        }]))
        .to_vec(),
        kernel_evidence_digest: sha256(&[]).to_vec(),
        refinement_evidence_digest: sha256(&[]).to_vec(),
        generation: 1,
    };
    let dictionary_digest = sha256(&canonical_dictionary(&[word]));
    bytes.extend(dictionary_digest);
    bytes.extend(sha256(&canonical_image_identity(
        FORMAT_VERSION,
        1,
        GAMMA_VERSION,
        &dictionary_digest,
    )));
    bytes
}

fn is_zero_digest(digest: &[u8]) -> bool {
    digest.iter().all(|byte| *byte == 0)
}
