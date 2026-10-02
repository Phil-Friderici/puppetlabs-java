# Acceptance tests (Puppet Litmus)

The acceptance tests in this directory use [Puppet Litmus](https://puppetlabs.github.io/litmus/)
to apply the module on real operating systems (docker containers or VMs) and verify the result
with RSpec and [serverspec](https://serverspec.org/) matchers.

## Layout

| File | Purpose |
|------|---------|
| `java_default_spec.rb` | `class { 'java': }` installs the default JDK, `java`/`javac` work, `JAVA_HOME` is set |
| `java_distribution_spec.rb` | `distribution => 'jre'` and `'jdk'` variants, unsupported distribution fails |
| `java_platform_spec.rb` | RedHat (alternatives), Debian (`update-java-alternatives`, `java-common`) and SLES specifics |
| `java_facts_spec.rb` | `java_version`, `java_major_version`, `java_patch_level`, `java_default_home`, `java_libjvm_path` |
| `java_multi_version_spec.rb` | `java::adoptium` and `java::sap` installing several versions side by side |
| `install_spec.rb` | Legacy scenarios (failure cases, Oracle, AdoptOpenJDK) |
| `../support/acceptance/java_helpers.rb` | Helpers: expected package names, versions and paths per platform |
| `../support/acceptance/shared_examples.rb` | Shared examples (idempotency, java binary, JDK, `JAVA_HOME`) |
| `../spec_helper_acceptance_local.rb` | Loads the helpers and prepares the target (e.g. `apt-get update`) |

Platform specific examples are skipped (reported as pending) on other platforms.

## Targets

The provisioning sets are defined in [`provision.yaml`](../../provision.yaml):

| Key | Provisioner | Targets |
|-----|-------------|---------|
| `default` | docker | Ubuntu 22.04 |
| `docker` | docker | Ubuntu 20.04, Ubuntu 22.04, Debian 11, CentOS 7, CentOS Stream 8 |
| `docker_ubuntu`, `docker_debian`, `docker_el7`, `docker_el8` | docker | subsets of `docker` |
| `docker_el_extended` | docker | Rocky Linux 8, AlmaLinux 8 |
| `sles` | provision_service | SLES 15 |
| `vagrant` | vagrant | local VMs |
| `release_checks` | provision_service | cloud VMs of all major platforms |

SLES has no public Litmus docker image; it needs the Puppet provision service (available to
GitHub Actions in the `puppetlabs` organisation) or a VM you provide yourself.

## Running the tests locally

Requirements: [PDK](https://www.puppet.com/docs/pdk/latest/pdk.html) (or Ruby with bundler) and docker.
Replace `pdk bundle exec` with `bundle exec` when not using PDK.

```bash
# 1. Provision the targets (one or many)
pdk bundle exec rake 'litmus:provision_list[default]'            # Ubuntu 22.04 only
pdk bundle exec rake 'litmus:provision_list[docker]'             # all docker targets
pdk bundle exec rake 'litmus:provision[docker,litmusimage/debian:11]'   # a single image

# 2. Install the puppet agent and the module under test
pdk bundle exec rake 'litmus:install_agent[puppet8]'
pdk bundle exec rake litmus:install_module

# 3. Run the tests against all provisioned targets in parallel
pdk bundle exec rake litmus:acceptance:parallel

# 4. Remove the targets
pdk bundle exec rake litmus:tear_down
```

Steps 1 and 2 can be combined: `pdk bundle exec rake 'litmus:provision_install[docker,puppet8]'`.

The provisioned targets are recorded in `spec/fixtures/litmus_inventory.yaml` (ignored by git).

### Useful variations

```bash
# Run a single spec file against a single target (see litmus_inventory.yaml for the names)
TARGET_HOST=localhost:52001 pdk bundle exec rspec spec/acceptance/java_facts_spec.rb

# After changing the module code, reinstall it on the targets
pdk bundle exec rake litmus:reinstall_module

# Use the puppetcore agent (requires a Puppet Forge token)
PUPPET_FORGE_TOKEN=<token> pdk bundle exec rake 'litmus:install_agent[puppetcore8]'
```

## Continuous integration

[`.github/workflows/litmus.yml`](../../.github/workflows/litmus.yml) runs the same steps for every
pull request against `main` (and on demand via *workflow_dispatch*):

* the `docker` job runs one matrix entry per docker image (Ubuntu 20.04/22.04, Debian 11, CentOS 7, CentOS Stream 8);
  the end-of-life CentOS releases are allowed to fail,
* the `cloud` job provisions SLES 15 through the Puppet provision service (only in the `puppetlabs` organisation).

If the `PUPPET_FORGE_TOKEN` secret is configured the `puppetcore8` agent is installed, otherwise `puppet8`.

## Writing new tests

* Require `spec_helper_acceptance` and use the Litmus helpers (`apply_manifest`, `idempotent_apply`,
  `run_shell`) together with serverspec resources (`package`, `file`, ...).
* Use the platform helpers (`redhat?`, `debian?`, `suse?`, `java_package_name`, `java_home`,
  `default_java_major_version`, ...) instead of hard coding values per platform.
* Prefer the shared examples, e.g.

  ```ruby
  it_behaves_like 'an idempotent manifest' do
    let(:manifest) { java_class_manifest(distribution: 'jre') }
  end
  ```

* Resolve target specific values lazily (inside examples, `let` or hooks) so that the spec files
  can be loaded without a provisioned target.
