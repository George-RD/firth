// A bounded JSON reader and writer for the VM's structured adapter boundary.
//
// The trusted VM stays dependency-free (`target-spec.md` §7 asks for a
// dependency-minimal, reviewable implementation), so the adapter parses its
// own transport rather than pulling a serialisation crate into the trusted
// computing base. The grammar accepted here is deliberately narrower than
// RFC 8259: numbers are integers only, duplicate object members are rejected,
// and both nesting and input size are bounded. Nothing in this file can
// change a semantic outcome: an adapter turns the parsed request into
// canonical image bytes and hands those to the same decoder every other
// caller uses.

/// The JSON value grammar this boundary accepts.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Json {
    /// The literal `null`.
    Null,
    /// A boolean literal.
    Bool(bool),
    /// An integer. Fractions and exponents are rejected, so a value that
    /// round-trips here is exact.
    Int(i64),
    /// A string with the standard escape set.
    Str(String),
    /// An array, in document order.
    Array(Vec<Json>),
    /// An object, in document order, with no repeated member name.
    Object(Vec<(String, Json)>),
}

/// Why a document was refused. Every case is a refusal, never a repair.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JsonError {
    /// The bytes are not a document in the accepted grammar.
    Malformed,
    /// An object repeated a member name.
    DuplicateMember,
    /// Nesting exceeded the bound.
    DepthLimit,
    /// The document exceeded the byte bound.
    TooLarge,
    /// A number was fractional, exponential, or outside `i64`.
    UnsupportedNumber,
}

impl JsonError {
    /// A stable code for this refusal.
    pub fn stable_code(self) -> &'static str {
        match self {
            Self::Malformed => "malformed-json",
            Self::DuplicateMember => "duplicate-member",
            Self::DepthLimit => "depth-limit",
            Self::TooLarge => "input-too-large",
            Self::UnsupportedNumber => "unsupported-number",
        }
    }
}

impl Json {
    /// The member named `name`, when this is an object that carries it.
    pub fn member(&self, name: &str) -> Option<&Json> {
        match self {
            Self::Object(members) => members
                .iter()
                .find(|(key, _)| key == name)
                .map(|(_, value)| value),
            _ => None,
        }
    }

    /// The member names of an object, in document order.
    pub fn member_names(&self) -> Vec<&str> {
        match self {
            Self::Object(members) => members.iter().map(|(key, _)| key.as_str()).collect(),
            _ => Vec::new(),
        }
    }
}

struct Reader1<'a> {
    bytes: &'a [u8],
    cursor: usize,
}

impl<'a> Reader1<'a> {
    fn new(bytes: &'a [u8]) -> Self {
        Self { bytes, cursor: 0 }
    }

    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.cursor).copied()
    }

    fn bump(&mut self) -> Option<u8> {
        let byte = self.peek()?;
        self.cursor += 1;
        Some(byte)
    }

    fn skip_whitespace(&mut self) {
        while matches!(self.peek(), Some(b' ' | b'\t' | b'\n' | b'\r')) {
            self.cursor += 1;
        }
    }

    fn expect(&mut self, byte: u8) -> Result<(), JsonError> {
        if self.bump() == Some(byte) {
            Ok(())
        } else {
            Err(JsonError::Malformed)
        }
    }

    fn literal(&mut self, word: &[u8]) -> Result<(), JsonError> {
        if self.bytes.len() < self.cursor + word.len()
            || &self.bytes[self.cursor..self.cursor + word.len()] != word
        {
            return Err(JsonError::Malformed);
        }
        self.cursor += word.len();
        Ok(())
    }
}

/// Parses one JSON document, refusing anything outside the accepted grammar.
pub fn parse_json(input: &str) -> Result<Json, JsonError> {
    if input.len() > MAX_BYTES {
        return Err(JsonError::TooLarge);
    }
    let mut reader = Reader1::new(input.as_bytes());
    reader.skip_whitespace();
    let value = parse_value(&mut reader, 0)?;
    reader.skip_whitespace();
    if reader.cursor != reader.bytes.len() {
        return Err(JsonError::Malformed);
    }
    Ok(value)
}

fn parse_value(reader: &mut Reader1<'_>, depth: usize) -> Result<Json, JsonError> {
    if depth > MAX_NESTING {
        return Err(JsonError::DepthLimit);
    }
    match reader.peek().ok_or(JsonError::Malformed)? {
        b'n' => {
            reader.literal(b"null")?;
            Ok(Json::Null)
        }
        b't' => {
            reader.literal(b"true")?;
            Ok(Json::Bool(true))
        }
        b'f' => {
            reader.literal(b"false")?;
            Ok(Json::Bool(false))
        }
        b'"' => Ok(Json::Str(parse_string(reader)?)),
        b'[' => parse_array(reader, depth),
        b'{' => parse_object(reader, depth),
        b'-' | b'0'..=b'9' => parse_number(reader),
        _ => Err(JsonError::Malformed),
    }
}

fn parse_array(reader: &mut Reader1<'_>, depth: usize) -> Result<Json, JsonError> {
    reader.expect(b'[')?;
    let mut items = Vec::new();
    reader.skip_whitespace();
    if reader.peek() == Some(b']') {
        reader.cursor += 1;
        return Ok(Json::Array(items));
    }
    loop {
        reader.skip_whitespace();
        items.push(parse_value(reader, depth + 1)?);
        reader.skip_whitespace();
        match reader.bump().ok_or(JsonError::Malformed)? {
            b',' => {}
            b']' => return Ok(Json::Array(items)),
            _ => return Err(JsonError::Malformed),
        }
    }
}

fn parse_object(reader: &mut Reader1<'_>, depth: usize) -> Result<Json, JsonError> {
    reader.expect(b'{')?;
    let mut members: Vec<(String, Json)> = Vec::new();
    reader.skip_whitespace();
    if reader.peek() == Some(b'}') {
        reader.cursor += 1;
        return Ok(Json::Object(members));
    }
    loop {
        reader.skip_whitespace();
        let name = parse_string(reader)?;
        if members.iter().any(|(key, _)| *key == name) {
            return Err(JsonError::DuplicateMember);
        }
        reader.skip_whitespace();
        reader.expect(b':')?;
        reader.skip_whitespace();
        let value = parse_value(reader, depth + 1)?;
        members.push((name, value));
        reader.skip_whitespace();
        match reader.bump().ok_or(JsonError::Malformed)? {
            b',' => {}
            b'}' => return Ok(Json::Object(members)),
            _ => return Err(JsonError::Malformed),
        }
    }
}

fn parse_string(reader: &mut Reader1<'_>) -> Result<String, JsonError> {
    reader.expect(b'"')?;
    let mut decoded = String::new();
    loop {
        match reader.bump().ok_or(JsonError::Malformed)? {
            b'"' => return Ok(decoded),
            b'\\' => decoded.push(parse_escape(reader)?),
            byte if byte < 0x20 => return Err(JsonError::Malformed),
            byte if byte < 0x80 => decoded.push(byte as char),
            byte => decoded.push(parse_utf8_tail(reader, byte)?),
        }
    }
}

fn parse_escape(reader: &mut Reader1<'_>) -> Result<char, JsonError> {
    match reader.bump().ok_or(JsonError::Malformed)? {
        b'"' => Ok('"'),
        b'\\' => Ok('\\'),
        b'/' => Ok('/'),
        b'b' => Ok('\u{8}'),
        b'f' => Ok('\u{c}'),
        b'n' => Ok('\n'),
        b'r' => Ok('\r'),
        b't' => Ok('\t'),
        b'u' => {
            let scalar = parse_hex4(reader)?;
            // Surrogate halves never denote a scalar value on their own; the
            // adapter refuses them rather than substituting a replacement.
            char::from_u32(scalar).ok_or(JsonError::Malformed)
        }
        _ => Err(JsonError::Malformed),
    }
}

fn parse_hex4(reader: &mut Reader1<'_>) -> Result<u32, JsonError> {
    let mut scalar = 0u32;
    for _ in 0..4 {
        let byte = reader.bump().ok_or(JsonError::Malformed)?;
        let digit = match byte {
            b'0'..=b'9' => u32::from(byte - b'0'),
            b'a'..=b'f' => u32::from(byte - b'a') + 10,
            b'A'..=b'F' => u32::from(byte - b'A') + 10,
            _ => return Err(JsonError::Malformed),
        };
        scalar = scalar * 16 + digit;
    }
    Ok(scalar)
}

fn parse_utf8_tail(reader: &mut Reader1<'_>, lead: u8) -> Result<char, JsonError> {
    let width = match lead {
        0xC2..=0xDF => 1,
        0xE0..=0xEF => 2,
        0xF0..=0xF4 => 3,
        _ => return Err(JsonError::Malformed),
    };
    let start = reader.cursor - 1;
    for _ in 0..width {
        let byte = reader.bump().ok_or(JsonError::Malformed)?;
        if !(0x80..=0xBF).contains(&byte) {
            return Err(JsonError::Malformed);
        }
    }
    core::str::from_utf8(&reader.bytes[start..reader.cursor])
        .map_err(|_| JsonError::Malformed)?
        .chars()
        .next()
        .ok_or(JsonError::Malformed)
}

fn parse_number(reader: &mut Reader1<'_>) -> Result<Json, JsonError> {
    let start = reader.cursor;
    if reader.peek() == Some(b'-') {
        reader.cursor += 1;
    }
    let digits = reader.cursor;
    while matches!(reader.peek(), Some(b'0'..=b'9')) {
        reader.cursor += 1;
    }
    if reader.cursor == digits {
        return Err(JsonError::Malformed);
    }
    // Reject a leading zero, a fraction, and an exponent: a value accepted
    // here has exactly one textual form, so a request cannot smuggle a
    // rounding difference past the adapter.
    if reader.bytes[digits] == b'0' && reader.cursor - digits > 1 {
        return Err(JsonError::Malformed);
    }
    if matches!(reader.peek(), Some(b'.' | b'e' | b'E')) {
        return Err(JsonError::UnsupportedNumber);
    }
    core::str::from_utf8(&reader.bytes[start..reader.cursor])
        .map_err(|_| JsonError::Malformed)?
        .parse::<i64>()
        .map(Json::Int)
        .map_err(|_| JsonError::UnsupportedNumber)
}

/// Renders a value in the canonical compact form: no whitespace, members in
/// the order they were built, and the minimal escape set.
pub fn render_json(value: &Json) -> String {
    let mut rendered = String::new();
    write_json(&mut rendered, value);
    rendered
}

fn write_json(out: &mut String, value: &Json) {
    match value {
        Json::Null => out.push_str("null"),
        Json::Bool(true) => out.push_str("true"),
        Json::Bool(false) => out.push_str("false"),
        Json::Int(number) => out.push_str(&number.to_string()),
        Json::Str(text) => write_json_string(out, text),
        Json::Array(items) => {
            out.push('[');
            for (index, item) in items.iter().enumerate() {
                if index != 0 {
                    out.push(',');
                }
                write_json(out, item);
            }
            out.push(']');
        }
        Json::Object(members) => {
            out.push('{');
            for (index, (name, item)) in members.iter().enumerate() {
                if index != 0 {
                    out.push(',');
                }
                write_json_string(out, name);
                out.push(':');
                write_json(out, item);
            }
            out.push('}');
        }
    }
}

fn write_json_string(out: &mut String, text: &str) {
    out.push('"');
    for character in text.chars() {
        match character {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            control if (control as u32) < 0x20 => {
                out.push_str("\\u");
                for shift in [12, 8, 4, 0] {
                    let digit = ((control as u32) >> shift) & 0xF;
                    out.push(char::from_digit(digit, 16).unwrap_or('0'));
                }
            }
            other => out.push(other),
        }
    }
    out.push('"');
}
