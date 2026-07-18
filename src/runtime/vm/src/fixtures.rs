fn fixture_stack(encoded: &str) -> Result<Vec<Value>, VmError> {
    if encoded == "-" || encoded.is_empty() {
        return Ok(Vec::new());
    }
    encoded
        .split(',')
        .map(|item| {
            if let Some(value) = item.strip_prefix("i:") {
                value
                    .parse()
                    .map(Value::Int)
                    .map_err(|_| VmError::InvalidLeb128)
            } else if item == "true" {
                Ok(Value::Bool(true))
            } else if item == "false" {
                Ok(Value::Bool(false))
            } else {
                item.parse()
                    .map(Value::Int)
                    .map_err(|_| VmError::InvalidLeb128)
            }
        })
        .collect()
}

fn fixture_dictionary(encoded: &str) -> Result<Vec<WordEntry>, VmError> {
    if encoded == "-" || encoded.is_empty() {
        return Ok(Vec::new());
    }
    encoded
        .split(';')
        .map(|entry| {
            let (name, code) = entry.split_once('=').ok_or(VmError::Truncated)?;
            Ok(fixture_word(name, fixture_code(code)?))
        })
        .collect()
}

fn fixture_code(encoded: &str) -> Result<Vec<Instruction>, VmError> {
    fixture_tokens(encoded)
        .into_iter()
        .filter(|token| !token.is_empty() && token != "-")
        .map(|token| fixture_instruction(&token))
        .collect()
}

fn fixture_tokens(encoded: &str) -> Vec<String> {
    let mut tokens = Vec::new();
    let mut start = 0;
    let mut depth = 0;
    for (index, byte) in encoded.bytes().enumerate() {
        match byte {
            b'[' => depth += 1,
            b']' => depth -= 1,
            b',' if depth == 0 => {
                tokens.push(String::from(&encoded[start..index]));
                start = index + 1;
            }
            _ => {}
        }
    }
    tokens.push(String::from(&encoded[start..]));
    tokens
}

fn fixture_instruction(token: &str) -> Result<Instruction, VmError> {
    let bare = token.trim_matches('"');
    let instruction = |op| Instruction { op, operand: None };
    match bare {
        "dup" => Ok(instruction(Op::Dup)),
        "drop" => Ok(instruction(Op::Drop)),
        "swap" => Ok(instruction(Op::Swap)),
        "call" => Ok(instruction(Op::Call)),
        "dip" => Ok(instruction(Op::Dip)),
        "compose" => Ok(instruction(Op::Compose)),
        "quote" => Ok(instruction(Op::Quote)),
        "if" => Ok(instruction(Op::If)),
        token if token.starts_with("word:") => Ok(Instruction {
            op: Op::CallWord,
            operand: Some(Operand::Word(String::from(&token[5..]))),
        }),
        token if token.starts_with("prim:") => Ok(Instruction {
            op: Op::Prim,
            operand: Some(Operand::Primitive(token[5..].trim_matches('"').into())),
        }),
        token if token.starts_with("pushi:") => Ok(Instruction {
            op: Op::PushLiteral,
            operand: Some(Operand::Literal(Value::Int(
                token[6..].parse().map_err(|_| VmError::InvalidLeb128)?,
            ))),
        }),
        token if token.starts_with("pushb:") => Ok(Instruction {
            op: Op::PushLiteral,
            operand: Some(Operand::Literal(Value::Bool(&token[6..] == "true"))),
        }),
        token if token.starts_with("pushq:[") && token.ends_with(']') => Ok(Instruction {
            op: Op::PushQuote,
            operand: Some(Operand::Quote(Quotation {
                code: fixture_code(&token[7..token.len() - 1])?,
                captures: Vec::new(),
                consumed: Vec::new(),
            })),
        }),
        _ => Err(VmError::InvalidOpcode(255)),
    }
}

fn fixture_word(name: &str, code: Vec<Instruction>) -> WordEntry {
    WordEntry {
        name: String::from(name),
        erased_word_type: String::from("(--)"),
        body_digest: sha256(&canonical_code(&code)).to_vec(),
        code,
        kernel_evidence_digest: sha256(&[]).to_vec(),
        refinement_evidence_digest: sha256(&[]).to_vec(),
        generation: 0,
    }
}

fn fixture_image(mut words: Vec<WordEntry>) -> Image {
    words.sort_by(|left, right| left.name.as_bytes().cmp(right.name.as_bytes()));
    let dictionary_digest = sha256(&canonical_dictionary(&words)).to_vec();
    Image {
        format_version: FORMAT_VERSION,
        image_version: 1,
        gamma_version: GAMMA_VERSION,
        image_digest: sha256(&canonical_image_identity(
            FORMAT_VERSION,
            1,
            GAMMA_VERSION,
            &dictionary_digest,
        ))
        .to_vec(),
        dictionary_digest,
        words,
    }
}

fn encode_image(image: &Image) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, u64::from(image.format_version));
    put_unsigned(&mut bytes, image.image_version);
    put_unsigned(&mut bytes, image.gamma_version);
    put_unsigned(&mut bytes, image.words.len() as u64);
    for word in &image.words {
        put_string(&mut bytes, &word.name);
        put_string(&mut bytes, &word.erased_word_type);
        bytes.extend(canonical_code(&word.code));
        bytes.extend(&word.body_digest);
        bytes.extend(&word.kernel_evidence_digest);
        bytes.extend(&word.refinement_evidence_digest);
        put_unsigned(&mut bytes, word.generation);
    }
    bytes.extend(&image.dictionary_digest);
    bytes.extend(&image.image_digest);
    bytes
}
