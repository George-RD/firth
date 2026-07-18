enum ResolvedWord<'a> {
    Borrowed {
        image: &'a Image,
        word: &'a WordEntry,
    },
    #[cfg(feature = "std")]
    Retained(WordHandle),
}

impl ResolvedWord<'_> {
    fn parts(&self) -> (&Image, &WordEntry) {
        match self {
            Self::Borrowed { image, word } => (image, word),
            #[cfg(feature = "std")]
            Self::Retained(handle) => (handle.image(), handle.entry()),
        }
    }
}

trait WordResolver {
    fn resolve<'a>(&'a self, name: &str) -> Result<ResolvedWord<'a>, VmError>;
}

struct StaticWordResolver<'a> {
    image: &'a Image,
}

struct ExecutionEnvironment<'a> {
    resolver: &'a dyn WordResolver,
    registry: &'a PrimitiveRegistry,
}

impl WordResolver for StaticWordResolver<'_> {
    fn resolve<'a>(&'a self, name: &str) -> Result<ResolvedWord<'a>, VmError> {
        let word = self
            .image
            .words
            .iter()
            .find(|word| word.name == name)
            .ok_or_else(|| VmError::UnknownWord(String::from(name)))?;
        Ok(ResolvedWord::Borrowed {
            image: self.image,
            word,
        })
    }
}
