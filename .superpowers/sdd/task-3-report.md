# Task 3 Report

## Outcome
Resolved the plan/test conflict by updating the launcher test to assert the real full file URL written into `policies.json`.

## Change made
- `tests/launch-prototype.test.sh`
  - Replaced the brittle `grep -Fq '"file://"'` check with an assertion against the exact installed addon URL:
    - `file://$app_dir/addons/vimium-c.xpi`
  - This matches the clarified requirement that the launcher must write a real full file URL.

## Verification
### Pre-fix observation
Command:
- `bash -x tests/launch-prototype.test.sh`

Output:
- Exit code `1`
- Failure occurred at:
  - `grep -Fq '"file://"' /.../firefox/distribution/policies.json`

### Post-fix focused check
Command:
- `bash tests/launch-prototype.test.sh`

Output:
- Exit code `0`
- No stdout/stderr

### Required suite
Command:
- `bash tests/profile-assets.test.sh && bash tests/build-prototype.test.sh && bash tests/launch-prototype.test.sh`

Output:
- Exit code `0`
- No stdout/stderr

## Notes
- `scripts/build-prototype.sh` and `scripts/launch-prototype.sh` were already aligned with the clarified behavior, so no production code changes were needed.
