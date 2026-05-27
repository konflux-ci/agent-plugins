# Using Trusted Maven Dependencies Skill

Updates a Maven project to source its dependencies from a trusted repository instead of Maven Central, ensuring rebuilds with security patches are used.

## What This Skill Does

This skill guides Claude Code to:
- **Prompt for required inputs** - Repository ID, URL, and rebuild version suffix
- **Check effective POM** - Detect whether the trusted repository is already configured
- **Add repository configuration** - Insert correct XML blocks in `<repositories>` and `<pluginRepositories>`
- **Replace dependency versions** - Update all dependency and plugin versions to their trusted rebuilds
- **Enforce semantic version equivalence** - Prevent accidental upgrades or downgrades during version replacement
- **Handle property-based versions** - Update `<properties>` rather than inline `<version>` elements

## When to Use

Invoke this skill when a Maven project needs to:
- Source dependencies from a company-internal or secured repository
- Replace publicly available artifacts with security-patched rebuilds
- Meet compliance requirements that prohibit direct Maven Central usage
- Adopt Konflux-style trusted artifact pipelines for Java/Maven builds

## Key Features

### Required Inputs

Before making changes, the skill prompts for:
1. **Repository ID** (`repository.id`) - kebab-case identifier for the Maven repository
2. **Repository URL** (`repository.url`) - HTTPS URL to the root of the Maven repository
3. **Rebuild Version Suffix** (`rebuild.suffix`) - Regex matching the suffix added to rebuilt versions (e.g., `redhat-[\d]+`)

### Repository Configuration

Adds XML blocks to both `<repositories>` (for dependencies) and `<pluginRepositories>` (for build plugins):

```xml
<!-- In <repositories> -->
<repository>
  <id>my-trusted-repo</id>
  <url>https://repo.example.com/maven2/</url>
  <releases><enabled>true</enabled></releases>
  <snapshots><enabled>false</enabled></snapshots>
</repository>

<!-- In <pluginRepositories> -->
<pluginRepository>
  <id>my-trusted-repo</id>
  <url>https://repo.example.com/maven2/</url>
  <releases><enabled>true</enabled></releases>
  <snapshots><enabled>false</enabled></snapshots>
</pluginRepository>
```

### Version Replacement Rules

- Trusted rebuilds share the same `groupId`, `artifactId`, and base `version` with a suffix appended
- When multiple rebuilds exist, select the **highest** version from `maven-metadata.xml`
- Semantic version (`MAJOR.MINOR.PATCH`) must match exactly — no upgrades or downgrades

**Allowed:**
```xml
<!-- Before -->
<version>5.8.2</version>
<!-- After (rebuild suffix: redhat-[\d]+) -->
<version>5.8.2-redhat-00001</version>
```

**Not allowed (version downgrade):**
```xml
<!-- Before: 5.9.3 -->
<version>5.9.3</version>
<!-- After: ← WRONG, base version downgraded -->
<version>5.8.2-redhat-00001</version>
```

### Property-Based Version Handling

When a version is set via a Maven property, update the property value in `<properties>` — not the `<version>` element itself:

```xml
<!-- Before -->
<my.lib.version>1.2.3</my.lib.version>

<!-- After -->
<my.lib.version>1.2.3-redhat-00001</my.lib.version>
```

## Process Overview

1. **Prompt for inputs** - Repository ID, URL, rebuild suffix
2. **Check effective POM** - Run `mvn help:effective-pom` to detect existing repository config
3. **Add repository** - If not already present, add to root `pom.xml` (exclude `src/` and `target/`)
4. **Replace versions** - Scan all `pom.xml` files, fetch `maven-metadata.xml` for each artifact, update versions

## Example Usage

```
User: "Update my Maven project to use our company's trusted artifact repository."

Claude (with skill):
1. Asks for repository ID (e.g., "company-trusted-repo")
2. Asks for repository URL (e.g., "https://artifacts.example.com/maven2/")
3. Asks for rebuild suffix (e.g., "rebuild-[\d]+")
4. Checks mvn help:effective-pom for existing config
5. Adds <repository> and <pluginRepository> blocks if needed
6. Scans all pom.xml files for dependency versions
7. Fetches maven-metadata.xml for each artifact from the trusted repo
8. Replaces matching semantic versions (same MAJOR.MINOR.PATCH) with trusted rebuilds
9. Updates <properties> entries when versions are property-referenced
10. Reports each replaced version
```

## What Makes This Skill Different

### Strict Version Semantics
- ✅ Replaces only exact semantic version matches
- ❌ Never upgrades or downgrades base version
- ❌ Never assumes a rebuild exists without checking the repository

### Complete Repository Coverage
- ✅ Adds both `<repositories>` and `<pluginRepositories>`
- ✅ Handles property-based versions via `<properties>`
- ✅ Scans all non-test pom.xml files recursively

### Validation First
- ✅ Checks effective POM before modifying anything
- ✅ Validates XML well-formedness after modification
- ✅ Skips already-configured repositories

## Prerequisites

- Maven installed (`mvn` on PATH)
- Network access to the trusted repository
- Project has a `pom.xml` at the root

## Known Issues

- **Script generation**: depending on the model and context, the LLM may decide to generate a bash or
  python script to fetch dependency metatdata from the trusted repository. A future version of this
  skill should provide an actual script to reduce token usage and improve overall determinism.
- **Private repositories**: this skill has not been tested against private Maven repositories
  that require authentication. The LLM may fail to obtain the necessary metadata in these scenarios.

## Version History

- **1.0.0** - Initial skill creation
  - Step-by-step process with input prompting
  - Effective POM verification
  - Semantic version enforcement
  - Property-based version handling
  - Both repository and pluginRepository configuration
