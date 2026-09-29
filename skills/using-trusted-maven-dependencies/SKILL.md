---
name: using-trusted-maven-dependencies
description: Use when updating a Maven project to source its dependencies from a trusted Maven repository instead of Maven Central.
allowed-tools: Bash(grep:*), Read, Edit, Bash(mkdir -p /tmp/use-trusted-maven-dependencies*), Bash(rm /tmp/use-trusted-maven-dependencies/*), Bash(mvn help:effective-pom*), WebFetch
---

# Use Trusted Maven Dependencies

Update a Maven project to use dependencies from a trusted Maven repository.
These repositories may publish rebuilds of publicly available dependencies in a secured environment,
and may include security patches absent from public repositories like Maven Central.

This skill will add the provided Maven repository as a source for code dependencies as well as 
Maven plugins. This ensures your Maven build maximizes the security of its entire supply chain.

## Input Variables

The following information will be provided by the user, and should be retained by the agent while it is executing this skill:

- `repository.id`
- `repository.url`
- `rebuild.suffix`

## Repository config template

The following XML blocks are referenced throughout this skill. Items in `${}` blocks are input
variables that will be provided by the user:

```xml
<!-- In <repositories> -->
<repository>
  <id>${repository.id}</id>
  <url>${repository.url}</url>
  <releases>
    <enabled>true</enabled>
  </releases>
  <snapshots>
    <enabled>false</enabled>
  </snapshots>
</repository>

<!-- In <pluginRepositories> -->
<pluginRepository>
  <id>${repository.id}</id>
  <url>${repository.url}</url>
  <releases>
    <enabled>true</enabled>
  </releases>
  <snapshots>
    <enabled>false</enabled>
  </snapshots>
</pluginRepository>
```

## Process

Follow these steps in order. Do not skip steps.

### 0. Prompt for Inputs

Ask the user to provide the following information:

1. "Repository ID" (`repository.id`): This is an identifier for the Maven repository, which should be a single kebab-case ID with alphanumeric characters.
2. "Repository URL" (`repository.url`): This is a valid HTTP URL to the root of the Maven repository. This url SHOULD use HTTPS.
3. "Rebuild Version Suffix" (`rebuild.suffix`): This is a suffix applied to rebuilt dependency versions. This can be a regular expression.

### 1. Check for the trusted repository

Print "Checking if the trusted repository is enabled..."

Run:
```
mkdir -p /tmp/use-trusted-maven-dependencies
mvn help:effective-pom -Doutput=/tmp/use-trusted-maven-dependencies/effective-pom.xml -q
```

Inspect `/tmp/use-trusted-maven-dependencies/effective-pom.xml`:
- If `<repositories>` contains an entry with `<id>${repository.id}</id>`, print "${repository.id} repository enabled."
- If `<pluginRepositories>` contains an entry with `<id>${repository.id}</id>`, print "${repository.id} plugin repository enabled."

Delete `/tmp/use-trusted-maven-dependencies/effective-pom.xml`.

If both are present, skip to step 3. Otherwise proceed to step 2.

### 2. Add trusted repository to root `pom.xml`

Print "Adding repository ${repository.id} to project pom.xml"

Find the project root `pom.xml` (ignore files under `src/` or `target/`). Add the `<repository>` block from the template above to `<repositories>`, and the `<pluginRepository>` block to `<pluginRepositories>`, creating each element if absent. Be sure to replace the input variables with values provided by the user.

Validate the modified `pom.xml` for well-formed XML and fix any syntax errors.

### 3. Replace dependency and plugin versions with trusted rebuilds

Scan all project `pom.xml` files (excluding those under `src/` or `target/`) for versions declared in:
- `<dependency>` elements (both inside `<dependencyManagement>` and standalone `<dependencies>`)
- `<plugin>` elements (including nested `<dependency>` elements within plugins)

For each artifact, use `WebFetch` to check the trusted repository for a rebuild. Fetch the
`maven-metadata.xml` at:
```
${repository.url}<groupId/as/path>/<artifactId>/maven-metadata.xml
```

Rebuilds share the same `groupId`, `artifactId`, and base `<version>`. Trusted rebuilds will have a
suffix appended to the `version` that matches the `${rebuild.suffix}` regular expression. The suffix
is separated from the base version by a hyphen (`-`), period (`.`), or plus sign (`+`). For example,
given base version `1.4.2` and suffix pattern `rebuild-[\d]+`, any of these are valid rebuild versions:
- `1.4.2-rebuild-0001`
- `1.4.2.rebuild-0001`
- `1.4.2+rebuild-0001`

If multiple rebuilds exist, select the highest version as reported in the repository's `maven-metadata.xml` file.

**Version properties:** If a version is set via a Maven property, update the property value in
`<properties>` rather than the `<version>` element. For example:

```xml
<!-- Before -->
<my.lib.version>1.2.3</my.lib.version>

<!-- After -->
<my.lib.version>1.2.3-redhat-00001</my.lib.version>
```

When replacing versions, you MUST ensure that the replaced version has an equivalent base version. DO NOT
upgrade or downgrade the base version during this process. For SemVer artifacts this means `MAJOR.MINOR.PATCH`
must match exactly. For non-SemVer artifacts (e.g., `31.1-jre`), the entire base version string before the
rebuild suffix must match.

**Allowed replacement**

Using `rebuild.suffix` = `myorg-[\d]*`

```xml
<!-- Before -->
<groupId>org.junit.jupiter</groupId>
<artifactId>junit-jupiter-api</artifactId>
<version>5.8.2</version>

<!-- After -->
<groupId>org.junit.jupiter</groupId>
<artifactId>junit-jupiter-api</artifactId>
<version>5.8.2.myorg-00002</version>
```

**Not allowed replacement (downgrade)**

Using `rebuild.suffix` = `myorg-[\d]*`

```xml
<!-- Before -->
<groupId>org.junit.jupiter</groupId>
<artifactId>junit-jupiter-api</artifactId>
<version>5.9.3</version>

<!-- After -->
<groupId>org.junit.jupiter</groupId>
<artifactId>junit-jupiter-api</artifactId>
<version>5.8.2.myorg-00002</version>
```

**Not allowed replacement (upgrade)**

Using `rebuild.suffix` = `myorg-[\d]*`

```xml
<!-- Before -->
<groupId>org.junit.jupiter</groupId>
<artifactId>junit-jupiter-api</artifactId>
<version>5.8.1</version>

<!-- After -->
<groupId>org.junit.jupiter</groupId>
<artifactId>junit-jupiter-api</artifactId>
<version>5.8.2.myorg-00002</version>
```

For each replaced version, print:
```
Replaced <groupId>:<artifactId>:<version> with trusted version <trustedVersion>
```

## Keywords

Maven, pom.xml, trusted repository, Maven Central, dependency management, pluginRepositories,
security patches, artifact rebuilds, supply chain security, version replacement, effective POM,
maven-metadata.xml, rebuild suffix, semver, Konflux, Java, build dependencies
