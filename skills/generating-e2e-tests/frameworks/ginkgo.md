# Ginkgo Adapter

How to write good Ginkgo v2 + Gomega E2E tests. Load this when the detected repo uses Ginkgo.
Repos: multi-platform-controller, may, tekton-kueue, external-secrets-operator.

## Style Rules

- `When()` not `Context()`
- Gomega matchers: `Expect(...).To/NotTo/ToNot(...)` for synchronous assertions;
  `Eventually/Consistently(...).Should/ShouldNot(...)` for async — don't mix them (`Expect(...)`
  has no `Should`)
- `DescribeTable` + `Entry` for repeated patterns across inputs
- Every `It` / `BeforeEach` / `AfterEach` takes `func(ctx context.Context)`
- `By()` to document each phase inside a test
- Explicit `Eventually(..., timeout, pollInterval)` — never rely on defaults for E2E
- Unique namespace per test; create in the spec, clean up in `AfterEach`

## Build Tags (conditional)

If the repo's existing E2E files start with a build tag (e.g. `//go:build e2e`), every new
test file MUST start with the same tag, and the run command MUST pass it (`-tags e2e`). Check
an existing test file first — if there's no tag, don't add one.

## Suite Setup with Prerequisite Check

```go
var _ = BeforeSuite(func() {
    cmd := exec.Command("kubectl", "api-resources", "--api-group=tekton.dev")
    _, err := utils.Run(cmd)
    Expect(err).NotTo(HaveOccurred(), "Tekton CRDs not found — is Tekton installed?")
})

func TestE2E(t *testing.T) {
    RegisterFailHandler(Fail)
    RunSpecs(t, "E2E Suite")
}
```

## K8s Client with Informer Cache

```go
func GetK8sClientOrDie(ctx context.Context) client.Client {
    scheme := runtime.NewScheme()
    utilruntime.Must(clientgoscheme.AddToScheme(scheme))
    utilruntime.Must(tekv1.AddToScheme(scheme))

    cfg := ctrl.GetConfigOrDie()
    k8sCache, err := cache.New(cfg, cache.Options{
        Scheme: scheme,
        ReaderFailOnMissingInformer: true,
    })
    Expect(err).ToNot(HaveOccurred())

    _, err = k8sCache.GetInformer(ctx, &tekv1.TaskRun{})
    Expect(err).ToNot(HaveOccurred())

    go func() {
        if err := k8sCache.Start(ctx); err != nil {
            panic(err)
        }
    }()
    k8sCache.WaitForCacheSync(ctx)

    k8sClient, err := client.New(cfg, client.Options{
        Cache:  &client.CacheOptions{Reader: k8sCache},
        Scheme: scheme,
    })
    Expect(err).ToNot(HaveOccurred())
    return k8sClient
}
```

## Test with Namespace Isolation + Debug Collection

```go
var _ = Describe("Feature under test", func() {
    var k8sClient client.Client
    testNamespace := ""
    testContext := &common.TestContext{}

    BeforeEach(func(ctx context.Context) {
        k8sClient = common.GetK8sClientOrDie(context.Background())
        Eventually(func(g Gomega) {
            podName := common.VerifyControllerPodRunning(g)
            testContext.SetControllerPodName(podName)
        }).Should(Succeed())
    })

    AfterEach(func(ctx context.Context) {
        common.CollectDebugInfo(ctx, k8sClient, testContext, testNamespace)
    })

    SetDefaultEventuallyTimeout(2 * time.Minute)
    SetDefaultEventuallyPollingInterval(time.Second)

    It("should do the expected thing", func(ctx context.Context) {
        testNamespace = "test-feature-name"
        By("Creating a namespace", func() {
            ns := &corev1.Namespace{ObjectMeta: metav1.ObjectMeta{Name: testNamespace}}
            err := k8sClient.Create(ctx, ns)
            if err != nil && !apierrors.IsAlreadyExists(err) {
                Expect(err).NotTo(HaveOccurred())
            }
        })
        By("Creating the resource under test")
        By("Waiting for the expected outcome")
        Eventually(func(g Gomega) {
            // check condition
        }, 20*time.Minute, 10*time.Second).Should(Succeed())
    })
})
```

## Failure Diagnostics (CollectDebugInfo)

Generic algorithm — the *resources* to dump come from the repo profile, the *shape* is constant:

```go
func CollectDebugInfo(ctx context.Context, k8sClient client.Client,
    testContext *TestContext, testNamespace string) {

    if !CurrentSpecReport().Failed() {
        return
    }
    logDir, err := getDebugLogDir() // from E2E_DEBUG_LOG_DIR
    if err != nil {
        return
    }
    os.MkdirAll(logDir, 0750)
    collectControllerPodInfo(testContext.ControllerPodName, logDir)
    collectEvents(logDir)
    // repo-specific resource dumps here — see repo profile
    collectPodsInfo(ctx, k8sClient, logDir, testNamespace)
}
```

Set `E2E_DEBUG_LOG_DIR` in CI, then upload as an artifact.

## DescribeTable for Variants

```go
DescribeTable("should run TaskRun on platform",
    func(ctx context.Context, platform, expectedArch string) {
        testNamespace = "test-" + strings.ReplaceAll(platform, "/", "-")
        // common test logic
    },
    Entry("linux/amd64", "linux/amd64", "x86_64"),
    Entry("linux/arm64", "linux/arm64", "aarch64"),
)
```

## Commands: what the skill validates vs. what only the developer/CI runs

Per SKILL Step 7 the skill **may compile/validate** the generated tests — never run them. Use
`go test -c` for test packages (`go build` skips `_test.go`, so it won't catch a test that
doesn't compile). Run these **from the Go module that owns the test** (Step 2):

```bash
go test -c ./test/e2e/<suite>/    # compile the test binary, run nothing (add -tags e2e if used)
go vet ./test/e2e/...             # type-checks test files too
go build ./...                    # production/helper code only — NOT proof a test compiles
```

The following **run the E2E suite** — developer / CI only, the skill never executes them:

```bash
make test-e2e
ginkgo -v ./test/e2e/<suite>/ --focus "<test name>"
```
