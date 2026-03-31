# DDEV with Rootless Docker (Nix Environment)

## Configuration for Non-Sudo Users

This project is configured to work with rootless Docker without requiring sudo access.

### Prerequisites Met

- ✅ Rootless Docker running via `dockerd-rootless`
- ✅ Docker buildx available (v0.31.1+)
- ✅ Nix-managed Docker environment
- ✅ User has Docker socket access: `/run/user/$UID/docker.sock`

### Global DDEV Configuration

```bash
# Applied settings:
ddev config global --no-bind-mounts         # Mutagen instead of bind mounts
ddev config global --router-http-port=8080  # Non-privileged port
ddev config global --router-https-port=8443 # Non-privileged port
```

### Buildx Plugin Setup (Nix)

For Nix environments, the docker-buildx plugin must be linked in the Docker CLI plugins directory:

```bash
# Location of buildx in Nix store:
# /nix/store/*/docker-buildx-*/libexec/docker/cli-plugins/docker-buildx

# Create symlink:
mkdir -p ~/.docker/cli-plugins
ln -sf /nix/store/*/docker-buildx-*/libexec/docker/cli-plugins/docker-buildx \
  ~/.docker/cli-plugins/

# Verify:
docker buildx version
```

### Environment Variables

Before running DDEV commands, ensure DOCKER_HOST is not set:

```bash
unset DOCKER_HOST
ddev start
```

**Why**: The DOCKER_HOST environment variable overrides Docker context selection and causes
buildx plugin lookup to fail. Rootless Docker automatically sets the correct socket path.

### Known Limitations & Workarounds

| Limitation | Workaround | Impact |
|-----------|-----------|--------|
| Privileged ports (< 1024) | Use ports 8080/8443 | Project URLs include port number |
| Bind mounts | Mutagen file sync | Slower file operations (acceptable for local dev) |
| File permissions | Mutagen handles sync | No permission changes needed |

### Mutagen Performance

File sync performance with `no-bind-mounts: true`:

```bash
# Monitor sync status:
ddev mutagen st drupal-playground -l

# Force sync flush:
ddev mutagen flush
```

Expected: 1-5 second initial sync, real-time updates after.

### Troubleshooting

**Problem**: `docker CLI plugin "buildx" not found`

**Solution**:
1. Verify buildx is installed: `docker buildx version`
2. Find it in Nix store: `find /nix -name docker-buildx 2>/dev/null`
3. Create symlink in `~/.docker/cli-plugins/`

**Problem**: `bind: permission denied` on port 80

**Solution**: DDEV is correctly configured with ports 8080/8443. Access via http://drupal-playground.ddev.site:8080

**Problem**: Mutagen sync is slow

**Solution**: This is expected with rootless Docker + Mutagen. Acceptable for local development.
To improve, consider:
- Checking `ddev mutagen st -l` for sync status
- Ensuring no large file changes are pending
- Using `ddev mutagen flush` to force sync

### For Team Members

If a team member uses rootless Docker without sudo:

1. Install buildx in `~/.docker/cli-plugins/` (symlink or copy from Nix store)
2. Run: `ddev config global --no-bind-mounts`
3. Run: `ddev config global --router-http-port=8080 --router-https-port=8443`
4. Use: `unset DOCKER_HOST && ddev start`

## References

- [DDEV Docker Rootless Docs](https://ddev.readthedocs.io/en/stable/users/install/docker-installation/#docker-rootless-mode)
- [Nix Docker](https://nixos.org/manual/nixpkgs/stable/#sec-docker)
- [Mutagen Sync](https://ddev.readthedocs.io/en/stable/users/install/performance/#mutagen)
