# frozen_string_literal: true

require_relative 'java_helpers/os_helpers'
require_relative 'java_helpers/java_facts_helpers'
require_relative 'java_helpers/manifest_helpers'

module JavaAcceptanceHelpers
  include JavaAcceptanceHelpers::OsHelpers
  include JavaAcceptanceHelpers::JavaFactsHelpers
  include JavaAcceptanceHelpers::ManifestHelpers

  JAVA_FACTS = ['java_version', 'java_major_version', 'java_patch_level', 'java_default_home', 'java_libjvm_path'].freeze

  class << self
    attr_accessor :cached_os_facts
  end

  module_function

  def target_shell(command, opts = {})
    LitmusHelper.instance.run_shell(command, opts)
  end

  def prepare_target
    target_shell('if command -v apt-get >/dev/null 2>&1; then apt-get update -qq; fi', expect_failures: true)
    LitmusHelper.instance.apply_manifest("package { 'curl': ensure => installed }", catch_failures: true)
  end
end
