impl ImageStore {
    pub fn new(image: Image) -> Result<Self, ImageError> {
        validate_image(&image).map_err(ImageError::InvalidImage)?;
        Ok(Self {
            state: Arc::new(RwLock::new(ImageState {
                active: Arc::new(image),
                retired: Vec::new(),
            })),
        })
    }

    pub fn snapshot(&self) -> Result<ImageHandle, ImageError> {
        let state = self.state.read().map_err(|_| ImageError::LockPoisoned)?;
        Ok(ImageHandle {
            image: Arc::clone(&state.active),
        })
    }

    pub fn lookup(&self, name: &str) -> Result<WordHandle, ImageError> {
        self.snapshot()?.lookup(name)
    }

    pub fn apply_patch(
        &self,
        patch: &WordPatch,
        verifier: &dyn PatchVerifier,
    ) -> Result<ImageHandle, ImageError> {
        self.apply_patch_using(
            patch,
            PatchServices {
                verifier,
                allocation: &GlobalImageAllocation,
            },
        )
    }

    fn apply_patch_using(
        &self,
        patch: &WordPatch,
        services: PatchServices<'_>,
    ) -> Result<ImageHandle, ImageError> {
        let base = self.snapshot()?;
        let candidate = prepare_patch(base.image(), patch, services)?;
        self.publish(patch.expected_image_version, candidate)
    }

    fn publish(&self, expected_version: u64, image: Image) -> Result<ImageHandle, ImageError> {
        let mut state = self.state.write().map_err(|_| ImageError::LockPoisoned)?;
        if state.active.image_version != expected_version {
            return Err(ImageError::StaleImage {
                expected: expected_version,
                actual: state.active.image_version,
            });
        }
        state
            .retired
            .try_reserve(1)
            .map_err(|_| ImageError::AllocationFailure)?;
        let published = Arc::new(image);
        let previous = core::mem::replace(&mut state.active, Arc::clone(&published));
        let retired_at = published.image_version;
        state.retired.push(RetiredImage {
            image: previous,
            retired_at,
        });
        Ok(ImageHandle { image: published })
    }

    pub fn rollback(
        &self,
        expected_current_version: u64,
        prior_version: u64,
    ) -> Result<ImageHandle, ImageError> {
        let mut state = self.state.write().map_err(|_| ImageError::LockPoisoned)?;
        if state.active.image_version != expected_current_version {
            return Err(ImageError::StaleImage {
                expected: expected_current_version,
                actual: state.active.image_version,
            });
        }
        let mut image = state
            .retired
            .iter()
            .find(|retired| retired.image.image_version == prior_version)
            .map(|retired| retired.image.as_ref().clone())
            .ok_or(ImageError::RollbackUnavailable(prior_version))?;
        image.image_version = state
            .active
            .image_version
            .checked_add(1)
            .ok_or(ImageError::VersionExhausted)?;
        image.image_digest = sha256(&canonical_image_identity(
            image.format_version,
            image.image_version,
            image.gamma_version,
            &image.dictionary_digest,
        ))
        .to_vec();
        validate_image(&image).map_err(ImageError::InvalidImage)?;
        state
            .retired
            .try_reserve(1)
            .map_err(|_| ImageError::AllocationFailure)?;
        let published = Arc::new(image);
        let previous = core::mem::replace(&mut state.active, Arc::clone(&published));
        state.retired.push(RetiredImage {
            image: previous,
            retired_at: published.image_version,
        });
        Ok(ImageHandle { image: published })
    }

    pub fn reclaim_through(&self, quiescent_epoch: u64) -> Result<Vec<u64>, ImageError> {
        let mut state = self.state.write().map_err(|_| ImageError::LockPoisoned)?;
        let mut reclaimed = Vec::new();
        reclaimed
            .try_reserve(state.retired.len())
            .map_err(|_| ImageError::AllocationFailure)?;
        state.retired.retain(|retired| {
            let reclaim = retired.retired_at <= quiescent_epoch
                && Arc::strong_count(&retired.image) == 1;
            if reclaim {
                reclaimed.push(retired.image.image_version);
            }
            !reclaim
        });
        Ok(reclaimed)
    }

    pub fn retired_versions(&self) -> Result<Vec<u64>, ImageError> {
        let state = self.state.read().map_err(|_| ImageError::LockPoisoned)?;
        Ok(state
            .retired
            .iter()
            .map(|retired| retired.image.image_version)
            .collect())
    }
}

struct ActiveWordResolver<'a> {
    store: &'a ImageStore,
}

impl WordResolver for ActiveWordResolver<'_> {
    fn resolve<'a>(&'a self, name: &str) -> Result<ResolvedWord<'a>, VmError> {
        self.store
            .lookup(name)
            .map(ResolvedWord::Retained)
            .map_err(|error| match error {
                ImageError::MissingWord(name) => VmError::UnknownWord(name),
                ImageError::AllocationFailure => VmError::AllocationFailure,
                _ => VmError::ResourceFault,
            })
    }
}

/// Executes `main` while resolving every dictionary call from the active image.
/// Each resolved word retains its image until that invocation returns.
pub fn execute_active(store: &ImageStore) -> Result<Vec<Value>, VmError> {
    Ok(execute_active_report(store, DEFAULT_FUEL, &default_registry())?.stack)
}

pub fn execute_active_report(
    store: &ImageStore,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> Result<ExecutionReport, VmError> {
    let resolver = ActiveWordResolver { store };
    let main = resolver.resolve("main")?;
    execute_report_resolved(main, &resolver, Vec::new(), fuel, registry)
}
