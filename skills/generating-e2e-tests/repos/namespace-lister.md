# namespace-lister

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [godog](../frameworks/godog.md) (Cucumber BDD, NOT Ginkgo)
- **What:** REST server returning user-accessible namespaces via RBAC. Pre-computed cache with informers
- **No controllers:** REST server using controller-runtime informers. Watches: Namespace, ClusterRoleBinding, RoleBinding, ClusterRole, Role

## Test locations (separate Go module)
```
acceptance/
├── go.mod              # Separate module
├── test/
│   ├── dumb-proxy/     # 7 scenarios (direct auth)
│   └── smart-proxy/    # 9 scenarios (behind proxy)
└── pkg/suite/          # Step definitions + hooks (hooks.go)
```

## Execution
- `make -C acceptance/test/dumb-proxy prepare && make -C acceptance/test/dumb-proxy test`
- `make -C acceptance/test/smart-proxy test`
- Cluster: 2 separate KinD clusters. Credentials: none

## Failure diagnostics (resources to dump)
**Currently NONE — confirmed gap (verified against upstream: `hooks.go` has only Before hooks, no `ctx.After`).** Add a `ctx.After` hook (when `err != nil`) dumping: Namespaces, RoleBindings, ClusterRoleBindings, ClusterRoles, Roles, pod logs, events.

## Dependencies
cert-manager v1.14.4 (oldest across repos), openresty proxy (smart-proxy).

## Notes
- Both dumb-proxy and smart-proxy must pass — they test different auth flows
- Acceptance tests build/load an image into KinD (Docker or Podman via `IMAGE_BUILDER`)
- Current scope: failure diagnostics only (see gap above); no coverage/Codecov work requested. Add only what the ticket recommends.
