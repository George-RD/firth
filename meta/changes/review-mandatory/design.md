# Design: review-mandatory

Deletion over classification: any exemption predicate is a classifier
whose edge cases the session must adjudicate mid-landing, which is
exactly the observed failure. Evidence lives on the PR as comments
because they are durable, human-readable, and mechanically queryable
(`gh pr view --json comments`); binding the head SHA makes a
post-review commit invalidate the review. The gate proves presence and
binding, not quality: comments remain session-authored attestations
whose audit trail is the transcript, now surfaced where a human can
read them on every PR.
